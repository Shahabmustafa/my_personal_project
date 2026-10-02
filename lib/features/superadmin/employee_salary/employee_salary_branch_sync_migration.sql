-- ─────────────────────────────────────────────────────────────────────────────
-- EMPLOYEE SALARY — branch sync
-- Users screen se kisi employee (manager / salesman / cashier) ki branch
-- badle to uske employee_salary record ki branch_id bhi khud badal jati hai.
-- Record (id) wahi rehta hai — purani invoices/returns/exchanges aur
-- employee_salary_history sahi rehte hain. Is mahine ka total_sales /
-- total_sales_return bhi record ke sath nayi branch par chala jata hai.
--
-- superadmin / admin / supervisor kai branches mein ho sakte hain, unka
-- salary record auto-move nahi hota.
-- Users screen pehle user_branches delete karti hai phir insert — is liye
-- trigger INSERT (aur UPDATE) par chalta hai.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.sync_employee_salary_branch()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_role text;
BEGIN
  SELECT role INTO v_role FROM public.users WHERE id = NEW.user_id;
  IF v_role IS NULL OR v_role IN ('superadmin', 'admin', 'supervisor') THEN
    RETURN NEW;
  END IF;

  UPDATE public.employee_salary
     SET branch_id = NEW.branch_id,
         updated_at = now()
   WHERE user_id = NEW.user_id
     AND branch_id IS DISTINCT FROM NEW.branch_id;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_sync_employee_salary_branch ON public.user_branches;
CREATE TRIGGER trg_sync_employee_salary_branch
  AFTER INSERT OR UPDATE OF branch_id ON public.user_branches
  FOR EACH ROW EXECUTE FUNCTION public.sync_employee_salary_branch();

-- Pehle se jo records galat branch par hain, unhein theek karo.
UPDATE public.employee_salary es
   SET branch_id = ub.branch_id,
       updated_at = now()
  FROM public.user_branches ub
  JOIN public.users u ON u.id = ub.user_id
 WHERE ub.user_id = es.user_id
   AND u.role NOT IN ('superadmin', 'admin', 'supervisor')
   AND es.branch_id IS DISTINCT FROM ub.branch_id;

NOTIFY pgrst, 'reload schema';
