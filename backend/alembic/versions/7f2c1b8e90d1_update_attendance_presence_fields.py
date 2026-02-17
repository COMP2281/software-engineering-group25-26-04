"""Update attendance presence fields

Revision ID: 7f2c1b8e90d1
Revises: ad45aed7988c
Create Date: 2026-02-17 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "7f2c1b8e90d1"
down_revision: Union[str, None] = "ad45aed7988c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("attendance", schema=None) as batch_op:
        batch_op.add_column(sa.Column("am_present", sa.Boolean(), nullable=False, server_default=sa.false()))
        batch_op.add_column(sa.Column("pm_present", sa.Boolean(), nullable=False, server_default=sa.false()))
        batch_op.add_column(sa.Column("on_site", sa.Boolean(), nullable=False, server_default=sa.false()))

    op.execute("UPDATE attendance SET am_present = present, pm_present = present, on_site = present")

    with op.batch_alter_table("attendance", schema=None) as batch_op:
        batch_op.drop_column("present")
        batch_op.alter_column("am_present", server_default=None)
        batch_op.alter_column("pm_present", server_default=None)
        batch_op.alter_column("on_site", server_default=None)


def downgrade() -> None:
    with op.batch_alter_table("attendance", schema=None) as batch_op:
        batch_op.add_column(sa.Column("present", sa.Boolean(), nullable=False, server_default=sa.false()))

    op.execute("UPDATE attendance SET present = am_present OR pm_present OR on_site")

    with op.batch_alter_table("attendance", schema=None) as batch_op:
        batch_op.drop_column("on_site")
        batch_op.drop_column("pm_present")
        batch_op.drop_column("am_present")
        batch_op.alter_column("present", server_default=None)
