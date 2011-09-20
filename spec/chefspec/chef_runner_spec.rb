require 'spec_helper'

module ChefSpec
  describe ChefRunner do
    describe "#initialize" do
      it "should create a node for use within the examples" do
        runner = ChefSpec::ChefRunner.new
        runner.node.should_not be_nil
      end
      it "should set the chef cookbook path to a default if not provided" do
        Chef::Config[:cookbook_path] = nil
        ChefSpec::ChefRunner.new
        Chef::Config[:cookbook_path].should_not be_nil
      end
      it "should set the chef cookbook path to any provided value" do
        ChefSpec::ChefRunner.new(:cookbook_path => '/tmp/foo')
        Chef::Config[:cookbook_path].should eql '/tmp/foo'
      end
      it "should default the log_level to warn" do
        Chef::Log.level.should eql :warn
      end
      it "should set the log_level to any provided value" do
        ChefSpec::ChefRunner.new(:log_level => :info)
        Chef::Log.level.should eql :info
      end
      it "should alias the real resource actions" do
        ChefSpec::ChefRunner.new
        Chef::Resource::File.method_defined?(:old_run_action).should be
      end
      it "should capture the resources created" do
        runner = ChefSpec::ChefRunner.new
        file = Chef::Resource::File.new '/tmp/foo.txt'
        file.run_action(:create)
        runner.resources.size.should == 1
        runner.resources.first.should equal(file)
      end
      it "should accept a block to set node attributes" do
        runner = ChefSpec::ChefRunner.new() {|node| node[:foo] = 'baz'}
        runner.node.foo.should == 'baz'
      end
      context "default ohai attributes" do
        let(:node){ChefSpec::ChefRunner.new.node}
        specify{node.os.should == 'chefspec'}
        specify{node.os_version.should == ChefSpec::VERSION}
        specify{node.fqdn.should == 'chefspec.local'}
        specify{node.domain.should == 'local'}
        specify{node.ipaddress.should == '127.0.0.1'}
        specify{node.hostname.should == 'chefspec'}
        specify{node.kernel.machine.should == 'i386'}
      end
    end
    describe "#converge" do
      it "should rethrow the exception if a cookbook cannot be found" do
        expect { ChefSpec::ChefRunner.new.converge('non_existent::default') }.to raise_error
            (Chef::Exceptions::CookbookNotFound)
      end
      it "should return a reference to the runner" do
        ChefSpec::ChefRunner.new.converge.respond_to?(:resources).should be_true
      end
    end
    describe "#node" do
      it "should allow attributes to be set on the node" do
        runner = ChefSpec::ChefRunner.new
        runner.node.foo = 'bar'
        runner.node.foo.should eq 'bar'
      end
    end
    describe "#file" do
      it "should not return a resource when the file has not been declared" do
        runner = ChefSpec::ChefRunner.new
        runner.resources = []
        runner.directory('/tmp/foo.txt').should_not be
      end
      it "should return a resource when the file has been declared" do
        runner = ChefSpec::ChefRunner.new
        runner.resources = [{:resource_name => 'file', :name => '/tmp/foo.txt'}]
        runner.file('/tmp/foo.txt').should be
      end
    end
    describe "#directory" do
      it "should not return a resource when the directory has not been declared" do
        runner = ChefSpec::ChefRunner.new
        runner.resources = []
        runner.directory('/tmp').should_not be
      end
      it "should return a resource when the directory has been declared" do
        runner = ChefSpec::ChefRunner.new
        runner.resources = [{:resource_name => 'directory', :name => '/tmp'}]
        runner.directory('/tmp').should be
      end
    end
  end
end