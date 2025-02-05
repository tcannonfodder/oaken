require "test_helper"

class OakenTest < ActiveSupport::TestCase
  test "version number" do
    refute_nil ::Oaken::VERSION
  end

  test "accessing fixture" do
    assert_equal "Kasper", users.kasper.name
    assert_equal "Coworker", users.coworker.name

    assert_equal [accounts.kaspers_donuts], users.kasper.accounts
    assert_equal [accounts.kaspers_donuts], users.coworker.accounts
    assert_equal [users.kasper, users.coworker], accounts.kaspers_donuts.users
  end

  test "accessing fixture from test env" do
    assert plans.test_premium
  end

  test "accessing fixture defined directly from label" do
    assert menus.basic
  end

  test "default attributes" do
    names = users.pluck(:name)

    (1..10).each do
      assert_includes names, "Customer #{_1}"
    end
  end

  test "source attribution" do
    donuts_location, kasper_location = [accounts.method(:kaspers_donuts), users.method(:kasper)].map(&:source_location)
    assert_match "db/seeds/accounts/kaspers_donuts.rb", donuts_location.first
    assert_match "db/seeds/accounts/kaspers_donuts.rb", kasper_location.first
    assert_operator donuts_location.second, :<, kasper_location.second

    assert_match "db/seeds/accounts/kaspers_donuts.rb", menus.method(:basic).source_location.first

    assert_match "db/seeds/data/plans.rb",      plans.method(:basic).source_location.first
    assert_match "db/seeds/test/data/plans.rb", plans.method(:test_premium).source_location.first
    assert_match "db/seeds/test/data/users.rb", users.method(:test_user).source_location.first
  end

  test "updating fixture" do
    users.kasper.update name: "Kasper2"
    assert_equal "Kasper2", users.kasper.name
  end

  test "upserting vs updating" do
    assert_equal "Basic", plans.basic.title

    error = assert_raises RuntimeError do
      plans.create title: "foo", price_cents: 0
    end
    assert_equal "after_save", error.message
  end

  test "respond_to_missing?" do
    mod = Oaken::Seeds.dup
    mod.undef_method :users # Remove built method
    assert mod.respond_to?(:users) # Now respond_to_missing? hits.
    refute mod.respond_to?(:hmhm)
  end
end
