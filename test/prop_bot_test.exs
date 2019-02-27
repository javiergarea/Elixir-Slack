defmodule PropBotTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest Slack.Bot

  defmodule Bot do
    use Slack
  end

  property "init formats rtm results properly" do
    check all token_test <- CustomDataGen.string_gen(),
              url_test <- CustomDataGen.url_gen(),
              self_name_test <- CustomDataGen.string_gen(),
              team_name_test <- CustomDataGen.string_gen(),
              bots_id_test <- CustomDataGen.id_gen("B"),
              channels_id_test <- CustomDataGen.id_gen("C"),
              groups_id_test <- CustomDataGen.id_gen("G"),
              users_id_test <- CustomDataGen.id_gen("U"),
              ims_id_test <- CustomDataGen.id_gen("D") do
      {:reconnect, %{slack: slack, bot_handler: bot_handler}} =
        Slack.Bot.init(%{
          bot_handler: Bot,
          rtm: %{
            url: url_test,
            self: %{name: self_name_test},
            team: %{name: team_name_test},
            bots: [%{id: bots_id_test}],
            channels: [%{id: channels_id_test}],
            groups: [%{id: groups_id_test}],
            users: [%{id: users_id_test}],
            ims: [%{id: ims_id_test}]
          },
          client: FakeWebsocketClient,
          token: token_test,
          initial_state: nil
        })

      assert bot_handler == Bot
      assert slack.me.name == self_name_test
      assert slack.team.name == team_name_test
      assert slack.bots == %{bots_id_test => %{id: bots_id_test}}
      assert slack.channels == %{channels_id_test => %{id: channels_id_test}}
      assert slack.groups == %{groups_id_test => %{id: groups_id_test}}
      assert slack.users == %{users_id_test => %{id: users_id_test}}
      assert slack.ims == %{ims_id_test => %{id: ims_id_test}}
    end
  end

  defmodule Stubs.Slack.Rtm do
    def connect(_token) do
      {:ok, %{url: "http://www.example.com"}}
    end
  end

  defmodule Stubs.Slack.WebsocketClient do
    def start_link(_url, _module, _state, _options) do
      {:ok, self()}
    end
  end

  property "can register the process with a given name" do
    check all name_test <- CustomDataGen.string_gen(),
              token_test <- CustomDataGen.string_gen() do
      original_slack_rtm = Application.get_env(:slack, :rtm_module, Slack.Rtm)

      Application.put_env(:slack, :rtm_module, Stubs.Slack.Rtm)

      {:ok, pid} =
        Slack.Bot.start_link(Bot, %{}, token_test, %{
          client: Stubs.Slack.WebsocketClient,
          name: String.to_atom(name_test)
        })

      Application.put_env(:slack, :rtm_module, original_slack_rtm)

      expected_pid = Process.whereis(String.to_atom(name_test))
      Process.unregister(String.to_atom(name_test))

      assert expected_pid == pid
    end
  end
end
