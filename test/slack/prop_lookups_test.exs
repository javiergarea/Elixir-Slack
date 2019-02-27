defmodule Slack.PropLookupsTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Slack.Lookups

  property "turns @user into a user identifier" do
    check all user_id_test <- CustomDataGen.id_gen("U"),
              user_name_test <- CustomDataGen.string_gen() do
      slack = %{
        users: %{
          user_id_test => %{
            name: user_name_test,
            id: user_id_test,
            profile: %{display_name: user_name_test}
          }
        }
      }

      assert Lookups.lookup_user_id("@#{user_name_test}", slack) == user_id_test
    end
  end

  property "turns @user into direct message identifier, if the channel exists" do
    check all user_id_test <- CustomDataGen.id_gen("U"),
              user_name_test <- CustomDataGen.string_gen(),
              ims_id_test <- CustomDataGen.id_gen("D") do
      slack = %{
        users: %{
          user_id_test => %{
            name: user_name_test,
            id: user_id_test,
            profile: %{display_name: user_name_test}
          }
        },
        ims: %{ims_id_test => %{user: user_id_test, id: ims_id_test}}
      }

      assert Lookups.lookup_direct_message_id("@#{user_name_test}", slack) == ims_id_test
      assert Lookups.lookup_direct_message_id("@missing#{user_name_test}", slack) == nil
    end
  end

  property "turns a user identifier into direct message identifier, if the channel exists" do
    check all ims_id_test <- CustomDataGen.id_gen("D"),
              user_id_test <- CustomDataGen.id_gen("U") do
      slack = %{
        ims: %{ims_id_test => %{user: user_id_test, id: ims_id_test}}
      }

      assert Lookups.lookup_direct_message_id(user_id_test, slack) == ims_id_test
      assert Lookups.lookup_direct_message_id("0#{user_id_test}", slack) == nil
    end
  end

  property "turns #channel into a channel identifier" do
    check all channel_id_test <- CustomDataGen.id_gen("C"),
              channel_name_test <- CustomDataGen.channel_name_gen() do
      slack = %{
        channels: %{
          channel_id_test => %{name: channel_name_test, id: channel_id_test}
        }
      }

      assert Lookups.lookup_channel_id("##{channel_name_test}", slack) == channel_id_test
    end
  end

  property "turns private #channel into a group identifier" do
    check all group_id_test <- CustomDataGen.id_gen("G"),
              group_name_test <- CustomDataGen.string_gen() do
      slack = %{
        channels: %{},
        groups: %{group_id_test => %{name: group_name_test, id: group_id_test}}
      }

      assert Lookups.lookup_channel_id("##{group_name_test}", slack) == group_id_test
    end
  end

  property "turns unknown #channel into nil" do
    check all channel_name_test <- CustomDataGen.channel_name_gen() do
      slack = %{
        channels: %{},
        groups: %{}
      }

      assert Lookups.lookup_channel_id("##{channel_name_test}", slack) == nil
    end
  end

  property "turns a user identifier into @user" do
    check all user_id_test <- CustomDataGen.id_gen("U"),
              user_name_test <- CustomDataGen.string_gen() do
      slack = %{
        users: %{
          user_id_test => %{
            name: user_name_test,
            id: user_id_test,
            profile: %{display_name: user_name_test}
          }
        }
      }

      assert Lookups.lookup_user_name(user_id_test, slack) == "@#{user_name_test}"
    end
  end

  property "turns a direct message identifier into @user" do
    check all user_id_test <- CustomDataGen.id_gen("U"),
              user_name_test <- CustomDataGen.string_gen(),
              ims_id_test <- CustomDataGen.id_gen("D") do
      slack = %{
        users: %{
          user_id_test => %{
            name: user_name_test,
            id: user_id_test,
            profile: %{display_name: user_name_test}
          }
        },
        ims: %{ims_id_test => %{user: user_id_test, id: ims_id_test}}
      }

      assert Lookups.lookup_user_name(ims_id_test, slack) == "@#{user_name_test}"
    end
  end

  property "turns a bot identifier into @user" do
    check all bot_id_test <- CustomDataGen.id_gen("B"),
              bot_name_test <- CustomDataGen.string_gen() do
      slack = %{
        bots: %{bot_id_test => %{name: bot_name_test, id: bot_id_test}}
      }

      assert Lookups.lookup_user_name(bot_id_test, slack) == "@#{bot_name_test}"
    end
  end

  property "turns a channel identifier into #channel" do
    check all channel_id_test <- CustomDataGen.id_gen("C"),
              channel_name_test <- CustomDataGen.channel_name_gen() do
      slack = %{
        channels: %{
          channel_id_test => %{name: channel_name_test, id: channel_id_test}
        }
      }

      assert Lookups.lookup_channel_name(channel_id_test, slack) ==
               "##{channel_name_test}"
    end
  end

  property "turns a private channel identifier into #channel" do
    check all group_id_test <- CustomDataGen.id_gen("G"),
              channel_name_test <- CustomDataGen.channel_name_gen() do
      slack = %{
        channels: %{},
        groups: %{
          group_id_test => %{name: channel_name_test, id: group_id_test}
        }
      }

      assert Lookups.lookup_channel_name(group_id_test, slack) ==
               "#" <> channel_name_test
    end
  end
end
