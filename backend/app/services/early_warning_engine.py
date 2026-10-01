from dataclasses import dataclass


@dataclass
class WarningSignal:
    warning_type: str
    severity: str
    title: str
    message: str
    trigger_value: str
    threshold_value: str
    recommended_action: str


class EarlyWarningEngine:

    @staticmethod
    def generate(
        attendance: float,
        academic_percentage: float,
        fee_due: float,
        engagement: float,
        risk_score: float,
        risk_level: str,
    ) -> list[WarningSignal]:

        warnings: list[WarningSignal] = []

        # ----------------------------------------------------
        # ATTENDANCE
        # ----------------------------------------------------

        if attendance < 60:
            warnings.append(
                WarningSignal(
                    warning_type="Attendance",
                    severity="High",
                    title="Critical Attendance Alert",
                    message=(
                        f"Attendance is {attendance:.1f}%, "
                        "which is below the critical monitoring threshold."
                    ),
                    trigger_value=f"{attendance:.1f}%",
                    threshold_value="< 60%",
                    recommended_action=(
                        "Advisor review recommended. Check attendance "
                        "barriers and academic participation."
                    ),
                )
            )
        elif attendance < 75:
            warnings.append(
                WarningSignal(
                    warning_type="Attendance",
                    severity="Medium",
                    title="Attendance Warning",
                    message=(
                        f"Attendance is {attendance:.1f}%, "
                        "which requires monitoring."
                    ),
                    trigger_value=f"{attendance:.1f}%",
                    threshold_value="< 75%",
                    recommended_action=(
                        "Monitor attendance and consider advisor follow-up."
                    ),
                )
            )

        # ----------------------------------------------------
        # ACADEMIC PERFORMANCE
        # ----------------------------------------------------

        if academic_percentage < 50:
            warnings.append(
                WarningSignal(
                    warning_type="Academic",
                    severity="High",
                    title="Academic Performance Alert",
                    message=(
                        f"Academic performance is "
                        f"{academic_percentage:.1f}%."
                    ),
                    trigger_value=f"{academic_percentage:.1f}%",
                    threshold_value="< 50%",
                    recommended_action=(
                        "Review academic performance and create "
                        "a targeted support plan."
                    ),
                )
            )
        elif academic_percentage < 65:
            warnings.append(
                WarningSignal(
                    warning_type="Academic",
                    severity="Medium",
                    title="Academic Performance Warning",
                    message=(
                        f"Academic performance is "
                        f"{academic_percentage:.1f}%."
                    ),
                    trigger_value=f"{academic_percentage:.1f}%",
                    threshold_value="< 65%",
                    recommended_action=(
                        "Monitor academic progress and identify "
                        "subjects requiring support."
                    ),
                )
            )

        # ----------------------------------------------------
        # FEES
        # ----------------------------------------------------

        if fee_due >= 25000:
            warnings.append(
                WarningSignal(
                    warning_type="Fees",
                    severity="High",
                    title="Outstanding Fee Alert",
                    message=(
                        f"Outstanding fees are INR {fee_due:,.0f}."
                    ),
                    trigger_value=f"INR {fee_due:,.0f}",
                    threshold_value=">= INR 25,000",
                    recommended_action=(
                        "Review the student's fee account and "
                        "available payment-support options."
                    ),
                )
            )
        elif fee_due >= 10000:
            warnings.append(
                WarningSignal(
                    warning_type="Fees",
                    severity="Medium",
                    title="Fee Due Warning",
                    message=(
                        f"Outstanding fees are INR {fee_due:,.0f}."
                    ),
                    trigger_value=f"INR {fee_due:,.0f}",
                    threshold_value=">= INR 10,000",
                    recommended_action=(
                        "Notify the student and monitor the outstanding balance."
                    ),
                )
            )

        # ----------------------------------------------------
        # ENGAGEMENT
        # ----------------------------------------------------

        if engagement < 40:
            warnings.append(
                WarningSignal(
                    warning_type="Engagement",
                    severity="High",
                    title="Low Engagement Alert",
                    message=(
                        f"Engagement is {engagement:.1f}%."
                    ),
                    trigger_value=f"{engagement:.1f}%",
                    threshold_value="< 40%",
                    recommended_action=(
                        "Advisor should review recent student engagement "
                        "and contact the student where appropriate."
                    ),
                )
            )
        elif engagement < 60:
            warnings.append(
                WarningSignal(
                    warning_type="Engagement",
                    severity="Medium",
                    title="Engagement Warning",
                    message=(
                        f"Engagement is {engagement:.1f}%."
                    ),
                    trigger_value=f"{engagement:.1f}%",
                    threshold_value="< 60%",
                    recommended_action=(
                        "Monitor engagement and consider student support."
                    ),
                )
            )

        # ----------------------------------------------------
        # OVERALL RISK
        # ----------------------------------------------------

        if risk_level == "High" or risk_score >= 70:
            warnings.append(
                WarningSignal(
                    warning_type="OverallRisk",
                    severity="High",
                    title="High Overall Student Risk",
                    message=(
                        f"Overall risk score is {risk_score:.1f}/100."
                    ),
                    trigger_value=f"{risk_score:.1f}",
                    threshold_value=">= 70",
                    recommended_action=(
                        "Create an intervention plan and assign an "
                        "appropriate advisor or support owner."
                    ),
                )
            )
        elif risk_level == "Medium" or risk_score >= 40:
            warnings.append(
                WarningSignal(
                    warning_type="OverallRisk",
                    severity="Medium",
                    title="Medium Overall Student Risk",
                    message=(
                        f"Overall risk score is {risk_score:.1f}/100."
                    ),
                    trigger_value=f"{risk_score:.1f}",
                    threshold_value=">= 40",
                    recommended_action=(
                        "Continue monitoring and consider preventive support."
                    ),
                )
            )

        return warnings
