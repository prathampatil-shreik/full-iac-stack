# Runbook — Terraform Plan Wants to Destroy and Recreate the Database

**Scenario:** `terraform plan` shows `-/+` (destroy and recreate) for the RDS instance.

## Steps

1. **Stop immediately.** Do not run `terraform apply`.

2. **Read the plan output carefully.** Identify the exact attribute causing replacement (e.g. `engine_version`, `identifier`, `db_subnet_group_name`).

3. **Determine why.** Common causes: changing `identifier`, `engine`, `db_subnet_group_name`, or `storage_type` forces replacement.

4. **Check for data.** If the database contains important data, take a manual snapshot via the AWS Console before proceeding.

5. **Decide intent.** If the replacement is unintended, correct the Terraform configuration to match the existing resource (use `lifecycle { ignore_changes }` if appropriate).

6. **Re-run `terraform plan`.** Confirm the replacement is no longer shown.

7. **Apply only after review.** If replacement is intentional and data is backed up, proceed with `terraform apply`.
