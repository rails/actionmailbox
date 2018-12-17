# frozen_string_literal: true

require "test_helper"
require "generators/rails/mailbox_generator"

class MailboxGeneratorTest < Rails::Generators::TestCase
  destination File.expand_path("../../tmp", File.dirname(__FILE__))
  setup :prepare_destination
  tests Rails::Generators::MailboxGenerator

  arguments ["inbox"]

  def test_mailbox_skeleton_is_created
    run_generator
    assert_file "app/mailboxes/inbox_mailbox.rb" do |mailbox|
      assert_match(/class InboxMailbox < ApplicationMailbox/, mailbox)
      assert_match(/def process/, mailbox)
      assert_no_match(%r{# routing /something/i => :somewhere}, mailbox)
    end
  end

  def test_application_mailbox_is_created
    Object.send :remove_const, :ApplicationMailbox
    run_generator ['application']
    assert_file "app/mailboxes/application_mailbox.rb" do |mailbox|
      assert_match(/class ApplicationMailbox < ActionMailbox::Base/, mailbox)
      assert_match(%r{# routing /something/i => :somewhere}, mailbox)
      assert_no_match(/def process/, mailbox)
    end
  end

  def test_check_class_collision
    Object.send :const_set, :InboxMailbox, Class.new
    content = capture(:stderr) { run_generator }
    assert_match(/The name 'InboxMailbox' is either already used in your application or reserved/, content)
  ensure
    Object.send :remove_const, :InboxMailbox
  end

  def test_invokes_default_test_framework
    run_generator %w(inbox foo bar -t=test_unit)
    assert_file "test/mailboxes/inbox_mailbox_test.rb" do |test|
      assert_match(/class InboxMailboxTest < ActionMailbox::TestCase/, test)
      assert_match(/# test "receive mail" do/, test)
      assert_match(/#     to: '"someone" <someone@example.com>,/, test)
    end
  end

  def test_actions_are_turned_into_methods
    run_generator %w(inbox foo bar)

    assert_file "app/mailboxes/inbox_mailbox.rb" do |mailbox|
      assert_instance_method :foo, mailbox
      assert_instance_method :bar, mailbox
    end
  end

  def test_mailbox_on_revoke
    run_generator
    run_generator ["inbox"], behavior: :revoke

    assert_no_file "app/mailboxes/inbox.rb"
  end

  def test_mailbox_suffix_is_not_duplicated
    run_generator %w(inbox_mailbox -t=test_unit)

    assert_no_file "app/mailboxes/inbox_mailbox_mailbox.rb"
    assert_file "app/mailboxes/inbox_mailbox.rb"

    assert_no_file "test/mailboxes/inbox_mailbox_mailbox_test.rb"
    assert_file "test/mailboxes/inbox_mailbox_test.rb"
  end
end
