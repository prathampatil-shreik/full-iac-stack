# policy/terraform/approved_instance_types_test.rego

package terraform.rds.instance_types

import rego.v1

# ── Passing ───────────────────────────────────────────────────────────────────

test_approved_class_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {"after": {"instance_class": "db.t3.micro"}},
		}],
	}
}

test_t4g_small_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {"after": {"instance_class": "db.t4g.small"}},
		}],
	}
}

# ── Failing ───────────────────────────────────────────────────────────────────

test_unapproved_class_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {"after": {"instance_class": "db.r5.4xlarge"}},
		}],
	}
	count(msgs) == 1
}

test_m5_large_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {"after": {"instance_class": "db.m5.large"}},
		}],
	}
	count(msgs) == 1
}
