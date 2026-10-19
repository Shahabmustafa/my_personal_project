-- Cross-branch sale return: customer ne maal Branch A se kharida, return
-- Branch B par ho raha hai. Return A ki invoice ke branch_id ke sath save hota
-- hai (stock aur refund A ko jate hain), lekin B ka user sirf apni branch ki
-- rows likh sakta hai (branch_write policy), is liye insert reject ho jata tha:
--   new row violates row-level security policy for table "sale_returns"
--
-- Naye INSERT-only policies: koi bhi authenticated user kisi bhi branch ka
-- return likh sakta hai, lekin sirf agar wo us branch ki asal invoice se
-- linked ho. Update / delete ab bhi sirf apni branch ke liye hain.

DROP POLICY IF EXISTS cross_branch_invoice_insert ON public.sale_returns;
CREATE POLICY cross_branch_invoice_insert ON public.sale_returns
  FOR INSERT TO authenticated
  WITH CHECK (
    original_invoice_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.sale_invoices i
      WHERE i.id = original_invoice_id AND i.branch_id = sale_returns.branch_id
    )
  );

-- Items / payments: parent return usi branch ka ho aur invoice-linked ho.
DROP POLICY IF EXISTS cross_branch_invoice_insert ON public.sale_return_items;
CREATE POLICY cross_branch_invoice_insert ON public.sale_return_items
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.sale_returns r
      WHERE r.id = sale_return_id
        AND r.branch_id = sale_return_items.branch_id
        AND r.original_invoice_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS cross_branch_invoice_insert ON public.sale_return_payments;
CREATE POLICY cross_branch_invoice_insert ON public.sale_return_payments
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.sale_returns r
      WHERE r.id = sale_return_id
        AND r.branch_id = sale_return_payments.branch_id
        AND r.original_invoice_id IS NOT NULL
    )
  );
