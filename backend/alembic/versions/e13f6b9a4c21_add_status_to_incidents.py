"""Add status column to incidents

Revision ID: e13f6b9a4c21
Revises: c9a4f2e31b77
Create Date: 2026-03-03 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e13f6b9a4c21"
down_revision: Union[str, None] = "c9a4f2e31b77"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    incident_columns = {column["name"] for column in inspector.get_columns("incidents")}

    if "status" in incident_columns:
        return

    with op.batch_alter_table("incidents", schema=None) as batch_op:
        batch_op.add_column(sa.Column("status", sa.String(length=50), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    incident_columns = {column["name"] for column in inspector.get_columns("incidents")}

    if "status" not in incident_columns:
        return

    with op.batch_alter_table("incidents", schema=None) as batch_op:
        batch_op.drop_column("status")
