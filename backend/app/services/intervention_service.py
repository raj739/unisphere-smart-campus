from dataclasses import dataclass


@dataclass
class InterventionPlan:
    intervention_type: str
    priority: str
    title: str
    reason: str
    recommended_action: str


class InterventionService:

    @staticmethod
    def create_plan(
        warning_type: str,
        severity: str,
        message: str,
        recommended_action: str,
    ) -> InterventionPlan:

        severity_map = {
            "High": "High",
            "Medium": "Medium",
            "Low": "Low",
        }

        priority = severity_map.get(severity, "Medium")

        intervention_map = {
            "Attendance": "Attendance Support",
            "Academic": "Academic Support",
            "Fees": "Financial Support",
            "Engagement": "Student Engagement",
            "OverallRisk": "Advisor Review",
        }

        intervention_type = intervention_map.get(
            warning_type,
            "Advisor Review",
        )

        return InterventionPlan(
            intervention_type=intervention_type,
            priority=priority,
            title=f"{intervention_type} Intervention",
            reason=message,
            recommended_action=recommended_action,
        )
