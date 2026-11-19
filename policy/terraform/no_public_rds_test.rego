# policy/terraform/no_public_rds_test.rego

package terraform.rds.public_access

import rego.v1

# ── Passing cases ─────────────────────────────────────────────────────────────

test_rds_not_public_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {"after": {
				"publicly_accessible": false,
				"storage_encrypted": true,
				"instance_class": "db.t3.micro",
			}},
		}],
	}
}

# ── Failing cases ─────────────────────────────────────────────────────────────

test_rds_public_denied if {
	count(deny) == 1 with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {"after": {
				"publicly_accessible": true,
				"storage_encrypted": true,
				"instance_class": "db.t3.micro",
			}},
		}],
	}
}
