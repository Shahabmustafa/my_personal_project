-- =============================================
-- sale_returns => employee_salary (MANAGER bhi)
-- Pehle return sirf salesman ke total_sales_return mein jata tha. Manager
-- ko har sale par commission milta hai, is liye return uske
-- total_sales_return mein bhi jana chahiye.
--
-- Manager kaun:
--   - original_invoice_id ho → us invoice ka manager_id (agar null ho to
--     koi manager nahi — us sale par kisi manager ko commission nahi mila)
--   - original_invoice_id na ho → us branch ka mojooda manager
-- =============================================
CREATE OR REPLACE FUNCTION public.return_manager_salary_id(
  p_original_invoice_id uuid,
  p_branch_id uuid
) RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public
AS $function$
  SELECT CASE
    WHEN p_original_invoice_id IS NOT NULL THEN
      (SELECT manager_id FROM public.sale_invoices
        WHERE id = p_original_invoice_id)
    ELSE
      (SELECT es.id FROM public.employee_salary es
         JOIN public.users u ON u.id = es.user_id
        WHERE es.branch_id = p_branch_id AND u.role = 'manager'
        LIMIT 1)
  END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_return_to_employee_salary()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  v_old_mgr uuid;
  v_new_mgr uuid;
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    IF OLD.salesman_id IS NOT NULL THEN
      UPDATE public.employee_salary
      SET total_sales_return = total_sales_return - OLD.total_amount
      WHERE id = OLD.salesman_id;
    END IF;

    v_old_mgr := public.return_manager_salary_id(OLD.original_invoice_id, OLD.branch_id);
    IF v_old_mgr IS NOT NULL THEN
      UPDATE public.employee_salary
      SET total_sales_return = total_sales_return - OLD.total_amount
      WHERE id = v_old_mgr;
    END IF;
  END IF;

  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    IF NEW.salesman_id IS NOT NULL THEN
      UPDATE public.employee_salary
      SET total_sales_return = total_sales_return + NEW.total_amount
      WHERE id = NEW.salesman_id;
    END IF;

    v_new_mgr := public.return_manager_salary_id(NEW.original_invoice_id, NEW.branch_id);
    IF v_new_mgr IS NOT NULL THEN
      UPDATE public.employee_salary
      SET total_sales_return = total_sales_return + NEW.total_amount
      WHERE id = v_new_mgr;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$function$;

-- Is mahine (Asia/Karachi) ke jo returns pehle ho chuke, unka amount
-- manager ke total_sales_return mein daal do. Pichle mahine already
-- history mein archive ho kar reset ho chuke hain — unhein nahi chhedte.
UPDATE public.employee_salary es
   SET total_sales_return = es.total_sales_return + x.amount
  FROM (
    SELECT public.return_manager_salary_id(r.original_invoice_id, r.branch_id) AS mgr,
           SUM(r.total_amount) AS amount
      FROM public.sale_returns r
     WHERE r.created_at >= (date_trunc('month', now() AT TIME ZONE 'Asia/Karachi')
                            AT TIME ZONE 'Asia/Karachi')
     GROUP BY 1
  ) x
 WHERE x.mgr = es.id;
