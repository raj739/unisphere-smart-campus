from dataclasses import dataclass


@dataclass
class RiskResult:
    score: float
    level: str
    attendance_score: float
    academic_score: float
    fee_score: float
    engagement_score: float
    explanation: str
    recommended_action: str


class RiskEngine:

    ATTENDANCE_WEIGHT = 0.40
    ACADEMIC_WEIGHT = 0.30
    FEE_WEIGHT = 0.15
    ENGAGEMENT_WEIGHT = 0.15

    @staticmethod
    def _attendance_risk(attendance: float) -> float:
        if attendance < 50:
            return 100.0
        if attendance < 60:
            return 85.0
        if attendance < 65:
            return 70.0
        if attendance < 70:
            return 55.0
        if attendance < 75:
            return 35.0
        if attendance < 80:
            return 20.0
        return 5.0

    @staticmethod
    def _academic_risk(academic_percentage: float) -> float:
        if academic_percentage < 40:
            return 100.0
        if academic_percentage < 50:
            return 85.0
        if academic_percentage < 60:
            return 70.0
        if academic_percentage < 65:
            return 55.0
        if academic_percentage < 70:
            return 35.0
        if academic_percentage < 75:
            return 20.0
        return 5.0

    @staticmethod
    def _fee_risk(fee_due: float) -> float:
        if fee_due >= 50000:
            return 100.0
        if fee_due >= 25000:
            return 80.0
        if fee_due >= 10000:
            return 60.0
        if fee_due >= 5000:
            return 35.0
        if fee_due > 0:
            return 15.0
        return 0.0

    @staticmethod
    def _engagement_risk(engagement: float) -> float:
        if engagement < 20:
            return 100.0
        if engagement < 40:
            return 75.0
        if engagement < 60:
            return 50.0
        if engagement < 80:
            return 25.0
        return 5.0

    @staticmethod
    def _level(score: float) -> str:
        if score >= 70:
            return "High"
        if score >= 40:
            return "Medium"
        return "Low"

    @classmethod
    def calculate(
        cls,
        attendance: float,
        academic_percentage: float,
        fee_due: float,
        engagement: float,
    ) -> RiskResult:

        attendance_score = cls._attendance_risk(attendance)
        academic_score = cls._academic_risk(academic_percentage)
        fee_score = cls._fee_risk(fee_due)
        engagement_score = cls._engagement_risk(engagement)

        score = (
            attendance_score * cls.ATTENDANCE_WEIGHT
            + academic_score * cls.ACADEMIC_WEIGHT
            + fee_score * cls.FEE_WEIGHT
            + engagement_score * cls.ENGAGEMENT_WEIGHT
        )

        score = round(min(max(score, 0.0), 100.0), 2)
        level = cls._level(score)

        factors = []

        if attendance_score >= 55:
            factors.append(
                f"attendance is {attendance:.1f}%"
            )

        if academic_score >= 55:
            factors.append(
                f"academic performance is {academic_percentage:.1f}%"
            )

        if fee_score >= 35:
            factors.append(
                f"outstanding fees are INR {fee_due:,.0f}"
            )

        if engagement_score >= 50:
            factors.append(
                f"engagement is {engagement:.1f}%"
            )

        if factors:
            explanation = (
                "Risk factors identified: "
                + "; ".join(factors)
                + "."
            )
        else:
            explanation = (
                "No major risk factors were identified from the "
                "available indicators."
            )

        if level == "High":
            action = (
                "Initiate advisor review and create an early "
                "intervention plan."
            )
        elif level == "Medium":
            action = (
                "Monitor the student closely and consider advisor "
                "follow-up."
            )
        else:
            action = (
                "Continue regular monitoring and academic support."
            )

        return RiskResult(
            score=score,
            level=level,
            attendance_score=round(attendance_score, 2),
            academic_score=round(academic_score, 2),
            fee_score=round(fee_score, 2),
            engagement_score=round(engagement_score, 2),
            explanation=explanation,
            recommended_action=action,
        )
