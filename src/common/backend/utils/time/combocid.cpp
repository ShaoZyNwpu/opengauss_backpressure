/* -------------------------------------------------------------------------
 *
 * combocid.c
 *	  Combo command ID support routines
 *
 * Before version 8.3, HeapTupleHeaderData had separate fields for cmin
 * and cmax.  To reduce the header size, cmin and cmax are now overlayed
 * in the same field in the header.  That usually works because you rarely
 * insert and delete a tuple in the same transaction, and we don't need
 * either field to remain valid after the originating transaction exits.
 * To make it work when the inserting transaction does delete the tuple,
 * we create a "combo" command ID and store that in the tuple header
 * instead of cmin and cmax. The combo command ID can be mapped to the
 * real cmin and cmax using a backend-private array, which is managed by
 * this module.
 *
 * To allow reusing existing combo cids, we also keep a hash table that
 * maps cmin,cmax pairs to combo cids.	This keeps the data structure size
 * reasonable in most cases, since the number of unique pairs used by any
 * one transaction is likely to be small.
 *
 * With a 32-bit combo command id we can represent 2^32 distinct cmin,cmax
 * combinations. In the most perverse case where each command deletes a tuple
 * generated by every previous command, the number of combo command ids
 * required for N commands is N*(N+1)/2.  That means that in the worst case,
 * that's enough for 92682 commands.  In practice, you'll run out of memory
 * and/or disk space way before you reach that limit.
 *
 * The array and hash table are kept in u_sess->top_transaction_mem_cxt, and are
 * destroyed at the end of each transaction.
 *
 *
 * Portions Copyright (c) 1996-2012, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/utils/time/combocid.c
 *
 * -------------------------------------------------------------------------
 */

#include "postgres.h"
#include "knl/knl_variable.h"

#include "access/htup.h"
#include "access/xact.h"
#include "utils/combocid.h"
#include "utils/hsearch.h"
#include "utils/memutils.h"

/* Key and entry structures for the hash table */
typedef struct ComboCidKeyData {
    CommandId cmin;
    CommandId cmax;
} ComboCidKeyData;

typedef ComboCidKeyData* ComboCidKey;

typedef struct {
    ComboCidKeyData key;
    CommandId combocid;
} ComboCidEntryData;

typedef ComboCidEntryData* ComboCidEntry;

/* Initial size of the hash table */
#define CCID_HASH_SIZE 100

/* Initial size of the array */
#define CCID_ARRAY_SIZE 100
/* If size is not enough, increase it */
#define CCID_ARRAY_INCSIZE 10000

/* prototypes for internal functions */
static CommandId GetComboCommandId(CommandId cmin, CommandId cmax);
static CommandId GetRealCmin(CommandId combocid);
static CommandId GetRealCmax(CommandId combocid);

/**** External API ****/

/*
 * GetCmin and GetCmax assert that they are only called in situations where
 * they make sense, that is, can deliver a useful answer.  If you have
 * reason to examine a tuple's t_cid field from a transaction other than
 * the originating one, use HeapTupleHeaderGetRawCommandId() directly.
 */

CommandId HeapTupleHeaderGetCmin(HeapTupleHeader tup, Page page)
{
    CommandId cid = HeapTupleHeaderGetRawCommandId(tup);

    Assert(TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetXmin(page, tup)));

    if (tup->t_infomask & HEAP_COMBOCID)
        return GetRealCmin(cid);
    else
        return cid;
}
CommandId HeapTupleGetCmin(HeapTuple tup)
{
    HeapTupleHeader htup = tup->t_data;
    CommandId cid = HeapTupleHeaderGetRawCommandId(htup);

    Assert(TransactionIdIsCurrentTransactionId(HeapTupleGetRawXmin(tup)));

    if (htup->t_infomask & HEAP_COMBOCID)
        return GetRealCmin(cid);
    else
        return cid;
}

CommandId HeapTupleGetCmax(HeapTuple tup)
{
    HeapTupleHeader htup = tup->t_data;
    CommandId cid = HeapTupleHeaderGetRawCommandId(htup);

    Assert(TransactionIdIsCurrentTransactionId(HeapTupleGetUpdateXid(tup)));

    if (htup->t_infomask & HEAP_COMBOCID)
        return GetRealCmax(cid);
    else
        return cid;
}

CommandId HeapTupleHeaderGetCmax(HeapTupleHeader tup, Page page)
{
    CommandId cid = HeapTupleHeaderGetRawCommandId(tup);

    Assert(TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetUpdateXid(page, tup)));

    if (tup->t_infomask & HEAP_COMBOCID)
        return GetRealCmax(cid);
    else
        return cid;
}

/* pass current_cid here just for logging, this case indicates delete after scan started */
bool CheckStreamCombocid(HeapTupleHeader tup, CommandId current_cid, Page page)
{
    CommandId cid = HeapTupleHeaderGetRawCommandId(tup);

    Assert(TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetXmin(page, tup)));

    /*
     * the top consumer may change its combocid information but cannot
     * update its producer stream thread's info simultaneously,
     * in this situation,  tuple should be deleted in current_command,
     * then return true, which means visiable for current command.
     * TO DO:
     * consumer and producer should have shared xact information context.
     */
    if (cid >= (unsigned)u_sess->utils_cxt.usedComboCids) {
        if (StreamThreadAmI() == true) {
            ereport(DEBUG1,
                (errmsg("Different combcid informations between consumer and producer"
                        "thread. Current_cid : %u, UsedComboCids: %d, tuple cid: %u.",
                    current_cid,
                    u_sess->utils_cxt.usedComboCids,
                    cid)));
            return true;
        } else {
            /* should not fall here */
            ereport(PANIC,
                (errmsg("Cannot found valid cid in UsedComboCids. UsedComboCids: %d, tuple cid: %u.",
                    u_sess->utils_cxt.usedComboCids,
                    cid)));
            /* keep compiler quiet */
            return false;
        }
    } else
        return false;
}

/*
 * Given a tuple we are about to delete, determine the correct value to store
 * into its t_cid field.
 *
 * If we don't need a combo CID, *cmax is unchanged and *iscombo is set to
 * FALSE.  If we do need one, *cmax is replaced by a combo CID and *iscombo
 * is set to TRUE.
 *
 * The reason this is separate from the actual HeapTupleHeaderSetCmax()
 * operation is that this could fail due to out-of-memory conditions.  Hence
 * we need to do this before entering the critical section that actually
 * changes the tuple in shared buffers.
 */
void HeapTupleHeaderAdjustCmax(HeapTupleHeader tup, CommandId* cmax, bool* iscombo, Buffer buffer)
{
    /*
     * If we're marking a tuple deleted that was inserted by (any
     * subtransaction of) our transaction, we need to use a combo command id.
     * Test for HEAP_XMIN_COMMITTED first, because it's cheaper than a
     * TransactionIdIsCurrentTransactionId call.
     */
    if (!HeapTupleHeaderXminCommitted(tup) &&
        TransactionIdIsCurrentTransactionId(HeapTupleHeaderGetXmin(BufferGetPage(buffer), tup))) {
        CommandId cmin = HeapTupleHeaderGetCmin(tup, BufferGetPage(buffer));

        *cmax = GetComboCommandId(cmin, *cmax);
        *iscombo = true;
    } else {
        *iscombo = false;
    }
}

/*
 * Combo command ids are only interesting to the inserting and deleting
 * transaction, so we can forget about them at the end of transaction.
 */
void AtEOXact_ComboCid(void)
{
    /*
     * Don't bother to pfree. These are allocated in u_sess->top_transaction_mem_cxt, so
     * they're going to go away at the end of transaction anyway.
     */
    u_sess->utils_cxt.comboHash = NULL;

    u_sess->utils_cxt.comboCids = NULL;
    u_sess->utils_cxt.usedComboCids = 0;
    u_sess->utils_cxt.sizeComboCids = 0;
    u_sess->utils_cxt.StreamParentComboCids = NULL;
    u_sess->utils_cxt.StreamParentsizeComboCids = 0;
}

/* Internal routines */
/*
 * Get a combo command id that maps to cmin and cmax.
 *
 * We try to reuse old combo command ids when possible.
 */
static CommandId GetComboCommandId(CommandId cmin, CommandId cmax)
{
    CommandId combocid;
    ComboCidKeyData key;
    ComboCidEntry entry = NULL;
    bool found = false;

    /*
     * Create the hash table and array the first time we need to use combo
     * cids in the transaction.
     */
    if (u_sess->utils_cxt.comboHash == NULL) {
        HASHCTL hash_ctl;
        int rc = 0;

        rc = memset_s(&hash_ctl, sizeof(hash_ctl), 0, sizeof(hash_ctl));
        securec_check(rc, "", "");
        hash_ctl.keysize = sizeof(ComboCidKeyData);
        hash_ctl.entrysize = sizeof(ComboCidEntryData);
        hash_ctl.hash = tag_hash;
        hash_ctl.hcxt = u_sess->top_transaction_mem_cxt;

        u_sess->utils_cxt.comboHash =
            hash_create("Combo CIDs", CCID_HASH_SIZE, &hash_ctl, HASH_ELEM | HASH_FUNCTION | HASH_CONTEXT);
    }

    if (u_sess->utils_cxt.comboCids == NULL) {
        u_sess->utils_cxt.comboCids = (ComboCidKeyData*)MemoryContextAlloc(
            u_sess->top_transaction_mem_cxt, sizeof(ComboCidKeyData) * CCID_ARRAY_SIZE);
        u_sess->utils_cxt.sizeComboCids = CCID_ARRAY_SIZE;
        u_sess->utils_cxt.usedComboCids = 0;
    }

    /* Lookup or create a hash entry with the desired cmin/cmax */
    /* We assume there is no struct padding in ComboCidKeyData! */
    key.cmin = cmin;
    key.cmax = cmax;
    entry = (ComboCidEntry)hash_search(u_sess->utils_cxt.comboHash, (void*)&key, HASH_ENTER, &found);

    if (found) {
        /* Reuse an existing combo cid */
        return entry->combocid;
    }

    /*
     * We have to create a new combo cid. Check that there's room for it in
     * the array, and grow it if there isn't.
     */
    if (u_sess->utils_cxt.usedComboCids >= u_sess->utils_cxt.sizeComboCids) {
        /* We need to grow the array */
        int newsize = u_sess->utils_cxt.sizeComboCids + CCID_ARRAY_INCSIZE;

        u_sess->utils_cxt.comboCids =
            (ComboCidKeyData*)repalloc(u_sess->utils_cxt.comboCids, sizeof(ComboCidKeyData) * newsize);
        u_sess->utils_cxt.sizeComboCids = newsize;
    }

    combocid = u_sess->utils_cxt.usedComboCids;

    u_sess->utils_cxt.comboCids[combocid].cmin = cmin;
    u_sess->utils_cxt.comboCids[combocid].cmax = cmax;
    u_sess->utils_cxt.usedComboCids++;

    entry->combocid = combocid;

    return combocid;
}

static CommandId GetRealCmin(CommandId combocid)
{
    Assert(combocid < (unsigned)u_sess->utils_cxt.usedComboCids);
    return u_sess->utils_cxt.comboCids[combocid].cmin;
}

static CommandId GetRealCmax(CommandId combocid)
{
    Assert(combocid < (unsigned)u_sess->utils_cxt.usedComboCids);
    return u_sess->utils_cxt.comboCids[combocid].cmax;
}

void StreamTxnContextSaveComboCid(void* stc)
{
    /* memcpy parent stream's comboCid info, we ignore comboHash becase stream producer only do read */
    if (u_sess->utils_cxt.comboCids && u_sess->utils_cxt.sizeComboCids != 0 && u_sess->utils_cxt.usedComboCids != 0) {
        if (u_sess->utils_cxt.StreamParentComboCids == NULL) {
            u_sess->utils_cxt.StreamParentComboCids = (ComboCidKeyData*)MemoryContextAlloc(
                u_sess->top_transaction_mem_cxt, sizeof(ComboCidKeyData) * u_sess->utils_cxt.sizeComboCids);
            u_sess->utils_cxt.StreamParentsizeComboCids = u_sess->utils_cxt.sizeComboCids;
        }

        if (u_sess->utils_cxt.sizeComboCids > u_sess->utils_cxt.StreamParentsizeComboCids) {
            u_sess->utils_cxt.StreamParentComboCids = (ComboCidKeyData*)repalloc(
                u_sess->utils_cxt.StreamParentComboCids, sizeof(ComboCidKeyData) * u_sess->utils_cxt.sizeComboCids);
            u_sess->utils_cxt.StreamParentsizeComboCids = u_sess->utils_cxt.sizeComboCids;
        }

        errno_t ret = memcpy_s(u_sess->utils_cxt.StreamParentComboCids,
            sizeof(ComboCidKeyData) * u_sess->utils_cxt.sizeComboCids,
            u_sess->utils_cxt.comboCids,
            sizeof(ComboCidKeyData) * u_sess->utils_cxt.usedComboCids);
        securec_check(ret, "\0", "\0");
    }
    STCSaveElem(((StreamTxnContext*)stc)->comboHash, u_sess->utils_cxt.comboHash);
    STCSaveElem(((StreamTxnContext*)stc)->comboCids, u_sess->utils_cxt.StreamParentComboCids);
    STCSaveElem(((StreamTxnContext*)stc)->usedComboCids, u_sess->utils_cxt.usedComboCids);
    STCSaveElem(((StreamTxnContext*)stc)->sizeComboCids, u_sess->utils_cxt.sizeComboCids);
}

void StreamTxnContextRestoreComboCid(void* stc)
{
    STCRestoreElem(((StreamTxnContext*)stc)->comboHash, u_sess->utils_cxt.comboHash);
    STCRestoreElem((ComboCidKey)(((StreamTxnContext*)stc)->comboCids), u_sess->utils_cxt.comboCids);
    STCRestoreElem(((StreamTxnContext*)stc)->usedComboCids, u_sess->utils_cxt.usedComboCids);
    STCRestoreElem(((StreamTxnContext*)stc)->sizeComboCids, u_sess->utils_cxt.sizeComboCids);
}
