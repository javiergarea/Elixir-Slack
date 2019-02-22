defmodule Slack.PropLookupsTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Slack.Lookups

  property "turns @user into a user identifier" do
    check all user_id_test <- CustomDataGen.custom_id_gen("U"),
              user_name_test <- StreamData.string(:ascii) do
      slack = %{
        users: %{
          (user_id_test) => %{
            name: user_name_test,
            id: user_id_test,
            profile: %{display_name: user_name_test}
          }
        }
      }

      assert Lookups.lookup_user_id("@" <> user_name_test, slack) == user_id_test
    end
  end

  property "turns @user into direct message identifier, if the channel exists" do
    check all user_id_test <- CustomDataGen.custom_id_gen("U"),
              user_name_test <- StreamData.string(:ascii),
              ims_id_test <- CustomDataGen.custom_id_gen("D") do
      slack = %{
        users: %{
          (user_id_test) => %{
            name: user_name_test,
            id: user_id_test,
            profile: %{display_name: user_name_test}
          }
        },
        ims: %{(ims_id_test) => %{user: user_id_test, id: ims_id_test}}
      }

      assert Lookups.lookup_direct_message_id("@" <> user_name_test, slack) == ims_id_test
      assert Lookups.lookup_direct_message_id("@missing" <> user_name_test, slack) == nil
    end
  end

  property "turns a user identifier into direct message identifier, if the channel exists" do
    check all ims_id_test <- CustomDataGen.custom_id_gen("D"),
              user_id_test <- CustomDataGen.custom_id_gen("U") do
      slack = %{
        ims: %{(ims_id_test) => %{user: user_id_test, id: ims_id_test}}
      }

      assert Lookups.lookup_direct_message_id(user_id_test, slack) == ims_id_test
      assert Lookups.lookup_direct_message_id("0" <> user_id_test, slack) == nil
    end
  end

  property "turns #channel into a channel identifier" do
    check all channels_id_test <- CustomDataGen.custom_id_gen("C"),
              channels_name_test <- StreamData.string(:ascii) do
      slack = %{
        channels: %{
          (channels_id_test) => %{name: channels_name_test, id: channels_id_test}
        }
      }

      assert Lookups.lookup_channel_id("#" <> channels_name_test, slack) == channels_id_test
    end
  end

  property "turns private #channel into a group identifier" do
    check all groups_id_test <- CustomDataGen.custom_id_gen("G"),
              groups_name_test <- StreamData.string(:ascii) do
      slack = %{
        channels: %{},
        groups: %{(groups_id_test) => %{name: groups_name_test, id: groups_id_test}}
      }

      assert Lookups.lookup_channel_id("#" <> groups_name_test, slack) == groups_id_test
    end
  end

  property "turns unknown #channel into nil" do
    check all channels_name_test <- StreamData.string(:ascii) do
      slack = %{
        channels: %{},
        groups: %{}
      }

      assert Lookups.lookup_channel_id("#" <> channels_name_test, slack) == nil
    end
  end

  property "turns a user identifier into @user" do
    check all user_id_test <- CustomDataGen.custom_id_gen("U"),
              user_name_test <- StreamData.string(:ascii) do
      slack = %{
        users: %{
          (user_id_test) => %{
            name: user_name_test,
            id: user_id_test,
            profile: %{display_name: user_name_test}
          }
        }
      }

      assert Lookups.lookup_user_name(user_id_test, slack) == "@" <> user_name_test
    end
  end

  property "turns a direct message identifier into @user" do
    check all user_id_test <- CustomDataGen.custom_id_gen("U"),
              user_name_test <- StreamData.string(:ascii),
              ims_id_test <- CustomDataGen.custom_id_gen("D") do
      slack = %{
        users: %{
          (user_id_test) => %{
            name: user_name_test,
            id: user_id_test,
            profile: %{display_name: user_name_test}
          }
        },
        ims: %{(ims_id_test) => %{user: user_id_test, id: ims_id_test}}
      }

      assert Lookups.lookup_user_name(ims_id_test, slack) == "@" <> user_name_test
    end
  end

  property "turns a bot identifier into @user" do
    check all bots_id_test <- CustomDataGen.custom_id_gen("B"),
              bots_name_test <- StreamData.string(:ascii) do
      slack = %{
        bots: %{(bots_id_test) => %{name: bots_name_test, id: bots_id_test}}
      }

      assert Lookups.lookup_user_name(bots_id_test, slack) == "@" <> bots_name_test
    end
  end

  property "turns a channel identifier into #channel" do
    check all channels_id_test <- CustomDataGen.custom_id_gen("C"),
              channels_name_test <- StreamData.string(:ascii) do
      slack = %{
        channels: %{
          (channels_id_test) => %{name: channels_name_test, id: channels_id_test}
        }
      }

      assert Lookups.lookup_channel_name(channels_id_test, slack) ==
               "#" <> channels_name_test
    end
  end

  property "turns a private channel identifier into #channel" do
    check all groups_id_test <- CustomDataGen.custom_id_gen("G"),
              channels_name_test <- StreamData.string(:ascii) do
      slack = %{
        channels: %{},
        groups: %{
          (groups_id_test) => %{name: channels_name_test, id: groups_id_test}
        }
      }

      assert Lookups.lookup_channel_name(groups_id_test, slack) ==
               "#" <> channels_name_test
    end
  end
end
