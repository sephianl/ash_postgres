# SPDX-FileCopyrightText: 2019 ash_postgres contributors <https://github.com/ash-project/ash_postgres/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPostgres.TestRepo.Migrations.AddPostsWithVersions do
  @moduledoc """
  Adds posts_with_versions table and version table for testing nested bulk updates with paper trail.
  """

  use Ecto.Migration

  def up do
    create table(:posts_with_versions, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true
      add :title, :text, null: false
      add :title2, :text
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end

    create table(:posts_with_versions_version, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true
      add :version_source_id, :binary_id, null: false
      add :version_action_type, :text, null: false
      add :version_action_name, :text
      add :version_action_inputs, :map
      add :version_resource_identifier, :text
      add :changes, :map, null: false, default: %{}
      add :actor_information, :map
      add :title, :text
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end

    create index(:posts_with_versions_version, [:version_source_id])
  end

  def down do
    drop table(:posts_with_versions_version)
    drop table(:posts_with_versions)
  end
end