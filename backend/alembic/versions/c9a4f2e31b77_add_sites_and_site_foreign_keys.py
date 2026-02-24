"""Add sites and site foreign keys

Revision ID: c9a4f2e31b77
Revises: 7f2c1b8e90d1
Create Date: 2026-02-17 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c9a4f2e31b77"
down_revision: Union[str, None] = "7f2c1b8e90d1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    access_columns = {column["name"] for column in inspector.get_columns("access_levels")}
    class_columns = {column["name"] for column in inspector.get_columns("classes")}
    student_columns = {column["name"] for column in inspector.get_columns("students")}
    students_already_updated = all(
        column_name not in student_columns
        for column_name in ["date_of_birth", "year_group", "has_disability", "disability_notes"]
    )

    if (
        inspector.has_table("sites")
        and "site_combination_id" in access_columns
        and "site_combination_id" in class_columns
        and "site_combination_id" in student_columns
        and students_already_updated
    ):
        return

    if not inspector.has_table("sites"):
        op.create_table(
            "sites",
            sa.Column("combination_id", sa.Integer(), nullable=False),
            sa.Column("site1", sa.Boolean(), nullable=False),
            sa.Column("site2", sa.Boolean(), nullable=False),
            sa.Column("site3", sa.Boolean(), nullable=False),
            sa.PrimaryKeyConstraint("combination_id"),
        )

        sites_table = sa.table(
            "sites",
            sa.column("combination_id", sa.Integer()),
            sa.column("site1", sa.Boolean()),
            sa.column("site2", sa.Boolean()),
            sa.column("site3", sa.Boolean()),
        )
        op.bulk_insert(
            sites_table,
            [
                {"combination_id": 1, "site1": True, "site2": False, "site3": False},
                {"combination_id": 2, "site1": False, "site2": True, "site3": False},
                {"combination_id": 3, "site1": False, "site2": False, "site3": True},
                {"combination_id": 4, "site1": True, "site2": False, "site3": True},
                {"combination_id": 5, "site1": False, "site2": True, "site3": True},
                {"combination_id": 6, "site1": True, "site2": True, "site3": True},
                {"combination_id": 7, "site1": True, "site2": True, "site3": False},
                {"combination_id": 8, "site1": False, "site2": False, "site3": False},
            ],
        )

    if "site_combination_id" not in access_columns:
        with op.batch_alter_table("access_levels", schema=None) as batch_op:
            batch_op.add_column(sa.Column("site_combination_id", sa.Integer(), nullable=True, server_default="8"))
            batch_op.create_foreign_key(
                "fk_access_levels_site_combination_id_sites",
                "sites",
                ["site_combination_id"],
                ["combination_id"],
            )

    if "site_combination_id" not in class_columns:
        with op.batch_alter_table("classes", schema=None) as batch_op:
            batch_op.add_column(sa.Column("site_combination_id", sa.Integer(), nullable=True, server_default="8"))
            batch_op.create_foreign_key(
                "fk_classes_site_combination_id_sites",
                "sites",
                ["site_combination_id"],
                ["combination_id"],
            )

    if "site_combination_id" not in student_columns:
        with op.batch_alter_table("students", schema=None) as batch_op:
            batch_op.add_column(sa.Column("site_combination_id", sa.Integer(), nullable=True, server_default="8"))
            batch_op.create_foreign_key(
                "fk_students_site_combination_id_sites",
                "sites",
                ["site_combination_id"],
                ["combination_id"],
            )

    with op.batch_alter_table("access_levels", schema=None) as batch_op:
        batch_op.alter_column("site_combination_id", existing_type=sa.Integer(), nullable=False, server_default=None)

    with op.batch_alter_table("classes", schema=None) as batch_op:
        batch_op.alter_column("site_combination_id", existing_type=sa.Integer(), nullable=False, server_default=None)

    with op.batch_alter_table("students", schema=None) as batch_op:
        batch_op.alter_column("site_combination_id", existing_type=sa.Integer(), nullable=False, server_default=None)
        if "disability_notes" in student_columns:
            batch_op.drop_column("disability_notes")
        if "has_disability" in student_columns:
            batch_op.drop_column("has_disability")
        if "year_group" in student_columns:
            batch_op.drop_column("year_group")
        if "date_of_birth" in student_columns:
            batch_op.drop_column("date_of_birth")


def downgrade() -> None:
    with op.batch_alter_table("students", schema=None) as batch_op:
        batch_op.add_column(sa.Column("date_of_birth", sa.Date(), nullable=True))
        batch_op.add_column(sa.Column("year_group", sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column("has_disability", sa.Boolean(), nullable=False, server_default=sa.false()))
        batch_op.add_column(sa.Column("disability_notes", sa.Text(), nullable=True))
        batch_op.drop_column("site_combination_id")

    with op.batch_alter_table("classes", schema=None) as batch_op:
        batch_op.drop_column("site_combination_id")

    with op.batch_alter_table("access_levels", schema=None) as batch_op:
        batch_op.drop_column("site_combination_id")

    op.drop_table("sites")
