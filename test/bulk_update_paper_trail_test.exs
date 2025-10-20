# SPDX-FileCopyrightText: 2019 ash_postgres contributors <https://github.com/ash-project/ash_postgres/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPostgres.BulkUpdatePaperTrailTest do
  use AshPostgres.RepoCase, async: false
  alias AshPostgres.Test.PostWithVersions
  alias AshPostgres.Test.PostWithoutVersions

  require Ash.Query

  describe "nested bulk operations with paper trail" do
    setup do
      # Create test posts
      posts = Ash.bulk_create!(
        [%{title: "test1"}, %{title: "test2"}, %{title: "test3"}],
        PostWithVersions,
        :create,
        return_stream?: true,
        return_records?: true,
        authorize?: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

      %{posts: posts}
    end

    test "second nested bulk update triggers BadMapError", %{posts: posts} do
      target_post = List.first(posts)

      # First call - should work
      result1 = [target_post]
                |> Ash.bulk_update!(:update_with_nested_bulk_update, %{},
                  resource: PostWithVersions,
                  domain: AshPostgres.Test.Domain,
                  strategy: :stream,
                  notify?: true,
                  return_records?: false,
                  authorize?: false
                )

      assert %Ash.BulkResult{} = result1

      # Second call - should trigger BadMapError
      # This mimics the GraphQL double-call scenario that causes:
      # ** (BadMapError) expected a map, got: nil
      #   (ash) lib/ash/actions/update/bulk.ex:2987: Ash.Actions.Update.Bulk.notification/3
      result2 = [target_post]
                |> Ash.bulk_update!(:update_with_nested_bulk_update, %{},
                  resource: PostWithVersions,
                  domain: AshPostgres.Test.Domain,
                  strategy: :stream,
                  notify?: true,
                  return_records?: false,
                  authorize?: false
                )

      assert %Ash.BulkResult{} = result2
    end

    test "supports bulk updates in after_action callbacks with notifications", %{posts: posts} do
      target_post = List.first(posts)

      assert %Ash.BulkResult{notifications: notifications} =
               [target_post]
               |> Ash.bulk_update!(:update_with_nested_bulk_update, %{},
                 resource: PostWithVersions,
                 domain: AshPostgres.Test.Domain,
                 strategy: :stream,
                 notify?: true,
                 return_notifications?: true,
                 return_records?: false,
                 authorize?: false
               )

      assert is_list(notifications)
    end

    test "supports nested operations with atomic strategy", %{posts: posts} do
      target_post = List.first(posts)

      assert %Ash.BulkResult{} =
               [target_post]
               |> Ash.bulk_update!(:update_with_nested_bulk_update, %{},
                 resource: PostWithVersions,
                 domain: AshPostgres.Test.Domain,
                 strategy: :atomic_batches,
                 notify?: true,
                 return_records?: false,
                 authorize?: false
               )
    end
  end

  describe "nested bulk operations WITHOUT paper trail (control test)" do
    setup do
      # Create test posts without paper trail
      posts = Ash.bulk_create!(
        [%{title: "test1"}, %{title: "test2"}, %{title: "test3"}],
        PostWithoutVersions,
        :create,
        return_stream?: true,
        return_records?: true,
        authorize?: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

      %{posts: posts}
    end

    @tag :control
    test "control: nested bulk update WITHOUT paper trail", %{posts: posts} do
      target_post = List.first(posts)

      # First call - should work
      result1 = [target_post]
                |> Ash.bulk_update!(:update_with_nested_bulk_update, %{},
                  resource: PostWithoutVersions,
                  domain: AshPostgres.Test.Domain,
                  strategy: :stream,
                  notify?: true,
                  return_records?: false,
                  authorize?: false
                )

      assert %Ash.BulkResult{} = result1

      # Second call - this should work if the bug is specific to AshPaperTrail
      # If this also fails, the bug is in nested bulk updates themselves
      result2 = [target_post]
                |> Ash.bulk_update!(:update_with_nested_bulk_update, %{},
                  resource: PostWithoutVersions,
                  domain: AshPostgres.Test.Domain,
                  strategy: :stream,
                  notify?: true,
                  return_records?: false,
                  authorize?: false
                )

      assert %Ash.BulkResult{} = result2
    end
  end
end