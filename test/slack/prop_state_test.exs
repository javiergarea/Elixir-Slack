defmodule Slack.PropStateTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Slack.State

  defp slack do
    %{
      channels: %{
        "123" => %{
          id: 123,
          name: "foo",
          is_member: nil,
          is_archived: nil,
          members: ["U123"]
        }
      },
      team: %{
        name: "Foo"
      },
      users: %{
        "123" => %{
          name: "Bar",
          presence: "active"
        },
        "U2" => %{
          name: "Baz",
          presence: "away"
        }
      },
      groups: %{
        "G000" => %{
          name: "secret-group",
          members: ["U111", "U222"]
        }
      },
      bots: %{
        "123" => %{
          name: "Bot"
        }
      },
      ims: %{}
    }
  end

  property "channel_joined sets is_member to true" do
    check all member1_test <- CustomDataGen.string_gen(),
              member2_test <- CustomDataGen.string_gen() do
      new_slack =
        State.update(
          %{type: "channel_joined", channel: %{id: "123", members: [member1_test, member2_test]}},
          slack()
        )

      assert new_slack.channels["123"].is_member == true
      assert new_slack.channels["123"].members == [member1_test, member2_test]
    end
  end

  property "channel_rename renames the channel" do
    check all name_test <- CustomDataGen.string_gen() do
      new_slack =
        State.update(
          %{type: "channel_rename", channel: %{id: "123", name: name_test}},
          slack()
        )

      assert new_slack.channels["123"].name == name_test
    end
  end

  property "team_rename renames team" do
    check all name_test <- CustomDataGen.string_gen() do
      new_slack =
        State.update(
          %{type: "team_rename", name: name_test},
          slack()
        )

      assert new_slack.team.name == name_test
    end
  end

  property "team_join adds user to users" do
    check all user_id_test <- CustomDataGen.id_gen("U"),
              user_id_test != "U2" do
      user_length = Map.size(slack().users)

      new_slack =
        State.update(
          %{type: "team_join", user: %{id: user_id_test}},
          slack()
        )

      assert Map.size(new_slack.users) == user_length + 1
    end
  end

  property "user_change updates user" do
    check all name_test <- CustomDataGen.string_gen() do
      new_slack =
        State.update(
          %{type: "user_change", user: %{id: "123", name: name_test}},
          slack()
        )

      assert new_slack.users["123"].name == name_test
      assert new_slack.users["123"].presence == "active"
    end
  end

  property "bot_added adds bot to bots" do
    check all bot_id_test <- CustomDataGen.id_gen("B"),
              bot_name_test <- CustomDataGen.string_gen() do
      bot_length = Map.size(slack().bots)

      new_slack =
        State.update(
          %{type: "bot_added", bot: %{id: bot_id_test, name: bot_name_test}},
          slack()
        )

      assert Map.size(new_slack.bots) == bot_length + 1
    end
  end

  property "bot_changed updates bot in bots" do
    check all name_test <- CustomDataGen.string_gen() do
      new_slack =
        State.update(
          %{type: "bot_changed", bot: %{id: "123", name: name_test}},
          slack()
        )

      assert new_slack.bots["123"].name == name_test
    end
  end

  property "channel_join message should add member" do
    check all user_id_test <- CustomDataGen.id_gen("U") do
      new_slack =
        State.update(
          %{type: "message", subtype: "channel_join", user: user_id_test, channel: "123"},
          slack()
        )

      assert new_slack.channels["123"].members |> Enum.sort() ==
               ["U123", user_id_test] |> Enum.sort()
    end
  end

  property "presence_change message should update user" do
    check all presence_test <- CustomDataGen.presence_gen() do
      new_slack =
        State.update(
          %{presence: presence_test, type: "presence_change", user: "123"},
          slack()
        )

      assert new_slack.users["123"].presence == presence_test
    end
  end

  property "bulk presence_change message should update users" do
    check all presence_test <- CustomDataGen.presence_gen() do
      new_slack =
        State.update(
          %{presence: presence_test, type: "presence_change", users: ["123", "U2"]},
          slack()
        )

      assert new_slack.users["123"].presence == presence_test
      assert new_slack.users["U2"].presence == presence_test
    end
  end

  property "group_joined event should add group" do
    check all member_test <- CustomDataGen.id_gen("U"),
              group_test <- CustomDataGen.id_gen("G") do
      new_slack =
        State.update(
          %{type: "group_joined", channel: %{id: group_test, members: ["U123", member_test]}},
          slack()
        )

      assert new_slack.groups[group_test]
      assert new_slack.groups[group_test].members == ["U123", member_test]
    end
  end

  property "group_join message should add user to member list" do
    check all user_id_test <- CustomDataGen.id_gen("U") do
      new_slack =
        State.update(
          %{type: "message", subtype: "group_join", channel: "G000", user: user_id_test},
          slack()
        )

      assert Enum.member?(new_slack.groups["G000"][:members], user_id_test)
    end
  end

  property "im_created message should add direct message channel to list" do
    check all channel_id_test <- CustomDataGen.id_gen("C") do
      channel = %{name: "channel", id: channel_id_test}

      new_slack =
        State.update(
          %{type: "im_created", channel: channel},
          slack()
        )

      assert new_slack.ims == %{channel_id_test => channel}
    end
  end

  property "user_change merges an existing user" do
    check all presence_test <- CustomDataGen.presence_gen(),
              nickname_test <- CustomDataGen.string_gen() do
      user = %{id: "123", presence: presence_test, nickname: nickname_test}

      new_slack =
        State.update(
          %{type: "user_change", user: user},
          slack()
        )

      assert new_slack.users["123"] == %{
               id: "123",
               name: "Bar",
               presence: presence_test,
               nickname: nickname_test
             }
    end
  end

  property "user_change adds a new user" do
    check all user_id_test <- CustomDataGen.id_gen("U"),
              user_presence_test <- CustomDataGen.presence_gen(),
              user_name_test <- CustomDataGen.string_gen() do
      user = %{id: user_id_test, presence: user_presence_test, name: user_name_test}

      new_slack =
        State.update(
          %{type: "user_change", user: user},
          slack()
        )

      assert new_slack.users[user_id_test] == %{
               id: user_id_test,
               name: user_name_test,
               presence: user_presence_test
             }
    end
  end
end
