from dataclasses import dataclass


@dataclass
class PaymentOrder:
    gateway_name: str
    gateway_order_id: str
    amount: float
    currency: str


class PaymentGateway:
    name = "mock"

    def create_order(
        self,
        transaction_number: str,
        amount: float,
        currency: str,
    ) -> PaymentOrder:
        raise NotImplementedError

    def verify_payment(
        self,
        gateway_transaction_id: str,
    ) -> bool:
        raise NotImplementedError


class MockPaymentGateway(PaymentGateway):
    name = "mock"

    def create_order(
        self,
        transaction_number: str,
        amount: float,
        currency: str,
    ) -> PaymentOrder:
        return PaymentOrder(
            gateway_name=self.name,
            gateway_order_id=f"MOCK-{transaction_number}",
            amount=amount,
            currency=currency,
        )

    def verify_payment(
        self,
        gateway_transaction_id: str,
    ) -> bool:
        return bool(gateway_transaction_id)


def get_payment_gateway() -> PaymentGateway:
    return MockPaymentGateway()
