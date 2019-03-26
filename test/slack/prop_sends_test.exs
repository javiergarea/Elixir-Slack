defmodule Slack.PropSendsTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Slack.Sends

  defmodule FakeWebsocketClient do
    def send({:text, json}, socket) do
      {json, socket}
    end

    def cast(pid, {:text, json}) do
      {pid, json}
    end
  end

  property "send_raw sends slack formatted to client" do
    check all text_test <- CustomDataGen.string_gen(),
              process_test <- StreamData.integer() do
      result =
        Sends.send_raw(~s/{"text": "#{text_test}"}/, %{
          process: process_test,
          client: FakeWebsocketClient
        })

      assert result == {process_test, ~s/{"text": "#{text_test}"}/}
    end
  end

  property "send_message sends message formatted to client" do
    check all message_test <- CustomDataGen.string_gen(),
              channel_name_test <- CustomDataGen.string_gen(),
              String.starts_with?(channel_name_test, "U") != true do
      result =
        Sends.send_message(message_test, channel_name_test, %{
          process: nil,
          client: FakeWebsocketClient
        })

      assert result ==
               {nil,
                ~s/{"type":"message","text":"#{message_test}","channel":"#{channel_name_test}"}/}
    end
  end

  property "send_message understands #channel names" do
    check all channel_id_test <- CustomDataGen.id_gen("C"),
              channel_name_test <- CustomDataGen.string_gen(),
              String.starts_with?(channel_name_test, "U") != true,
              message_test <- CustomDataGen.string_gen() do
      slack = %{
        process: nil,
        client: FakeWebsocketClient,
        channels: %{
          channel_id_test => %{name: channel_name_test, id: channel_id_test}
        }
      }

      result = Sends.send_message(message_test, "##{channel_name_test}", slack)

      assert result ==
               {nil,
                ~s/{"type":"message","text":"#{message_test}","channel":"#{channel_id_test}"}/}
    end
  end

  property "send_message raises an ArgumentException when channel does not exist" do
    check all channel_id_test <- CustomDataGen.id_gen("C"),
              channel_name_test <- CustomDataGen.string_gen(),
              group_id_test <- CustomDataGen.id_gen("G"),
              message_test <- CustomDataGen.string_gen() do
      slack = %{
        process: nil,
        client: FakeWebsocketClient,
        channels: %{
          channel_id_test => %{name: channel_name_test, id: channel_id_test}
        },
        groups: %{
          group_id_test => %{name: channel_name_test, id: group_id_test}
        }
      }

      assert_raise ArgumentError, "channel ##{channel_name_test}2 not found", fn ->
        Sends.send_message(message_test, "##{channel_name_test}2", slack)
      end
    end
  end

  property "send_message understands @user names" do
    check all user_id_test <- CustomDataGen.id_gen("U"),
              user_name_test <- CustomDataGen.string_gen(),
              ims_id_test <- CustomDataGen.id_gen("D"),
              message_test <- CustomDataGen.string_gen() do
      slack = %{
        process: nil,
        client: FakeWebsocketClient,
        users: %{user_id_test => %{name: user_name_test, id: user_id_test}},
        ims: %{ims_id_test => %{user: user_id_test, id: ims_id_test}}
      }

      result = Sends.send_message(message_test, "@#{user_name_test}", slack)

      assert result ==
               {nil, ~s/{"type":"message","text":"#{message_test}","channel":"#{ims_id_test}"}/}
    end
  end

  property "send_message understands user ids (Uxxx)" do
    check all user_id_test <- CustomDataGen.id_gen("U"),
              user_name_test <- CustomDataGen.string_gen(),
              ims_id_test <- CustomDataGen.id_gen("D"),
              message_test <- CustomDataGen.string_gen() do
      slack = %{
        process: nil,
        client: FakeWebsocketClient,
        users: %{user_id_test => %{name: user_name_test, id: user_id_test}},
        ims: %{ims_id_test => %{user: user_id_test, id: ims_id_test}}
      }

      result = Sends.send_message(message_test, user_id_test, slack)

      assert result ==
               {nil, ~s/{"type":"message","text":"#{message_test}","channel":"#{ims_id_test}"}/}
    end
  end

  property "indicate_typing sends typing notification to client" do
    check all channel_name_test <- CustomDataGen.string_gen(),
              String.starts_with?(channel_name_test, "U") != true do
      result =
        Sends.indicate_typing(channel_name_test, %{process: nil, client: FakeWebsocketClient})

      assert result == {nil, ~s/{"type":"typing","channel":"#{channel_name_test}"}/}
    end
  end

  property "send_ping with data sends ping + data to client" do
    check all data_test <- CustomDataGen.map_gen() do
      result = Sends.send_ping(data_test, %{process: nil, client: FakeWebsocketClient})

      [key] = Map.keys(data_test)
      data_string = ~s/"#{key}":"#{Map.get(data_test, key)}"/
      {nil, result_string} = result
      assert result_string == ~s/{#{data_string}, "type":"ping",}/
    end
  end

  property "subscribe_presence sends presence subscription message to client" do
    check all user_id_list_test <- CustomDataGen.list_of_user_ids_gen() do
      result =
        Sends.subscribe_presence(user_id_list_test, %{process: nil, client: FakeWebsocketClient})

      assert result ==
               {nil,
                ~s/{"type":"presence_sub","ids":#{
                  Kernel.inspect(user_id_list_test) |> String.replace(", ", ",")
                }}/}
    end
  end
end
