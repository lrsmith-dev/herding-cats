terraform {
  required_providers {
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = ">= 2.2.1"
    }
  }
}

provider "pagerduty" {
  token = var.pagerduty_token
}

## Boiler plate for testing
resource "pagerduty_user" "sre" {
  name  = "SRE Engineer"
  email = "sre.engineer@lrsmith.dev"
  role  = "observer"
}

resource "pagerduty_user" "mgr" {
  name  = "SRE Manager"
  email = "sre.manager@lrsmith.dev"
  role  = "user"
}

resource "pagerduty_team_membership" "sre" {
  user_id = pagerduty_user.sre.id
  team_id = pagerduty_team.Team_One.id
  role    = "responder"
}

resource "pagerduty_team_membership" "mgr" {
  user_id = pagerduty_user.mgr.id
  team_id = pagerduty_team.Team_One.id
  role    = "manager"
}
##


# Create a Pagerduty Team to Teams to manage their Pagerduty Configs
resource "pagerduty_team" "Team_One" {
  name        = "Team One"
  description = "The Dream Team"
}

# Create a Pagerduty Escalation policy for the team.
resource "pagerduty_escalation_policy" "Team_One" {
  name      = "Team One Escalation Policy"
  num_loops = 2
  teams = [pagerduty_team.Team_One.id]

  rule {
    escalation_delay_in_minutes = 10
    target {
      type = "user_reference"
      id   = pagerduty_user.sre.id
    }
  }
  rule {
    escalation_delay_in_minutes = 10
    target {
      type = "user_reference"
      id   = pagerduty_user.mgr.id
    }
  }
}

resource "pagerduty_service" "Team_One" {
  name                    = "Guardian - Team One"
  auto_resolve_timeout    = 14400
  acknowledgement_timeout = 600
  escalation_policy       = pagerduty_escalation_policy.Team_One.id
  alert_creation          = "create_alerts_and_incidents"

  auto_pause_notifications_parameters {
    enabled = true
    timeout = 300
  }
}


