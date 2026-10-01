# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'java class platform specific behaviour' do
  before(:all) do
    apply_manifest(java_class_manifest, catch_failures: true)
  end

  context 'on RedHat family' do
    before(:each) { skip("not a RedHat target (#{os_family})") unless redhat? }

    it 'registers java with the alternatives system' do
      expect(run_shell('alternatives --display java').stdout).to match(%r{^java - status is})
    end

    it 'links /usr/bin/java through /etc/alternatives' do
      expect(file('/usr/bin/java')).to be_linked_to('/etc/alternatives/java')
    end

    it_behaves_like 'a configured JAVA_HOME' do
      let(:expected_java_home) { java_home }
    end
  end

  context 'on Debian family' do
    before(:each) { skip("not a Debian target (#{os_family})") unless debian? }

    it_behaves_like 'an installed java package' do
      let(:package_name) { 'java-common' }
    end

    it 'registers the OpenJDK alternative for update-java-alternatives' do
      expect(file("/usr/lib/jvm/.#{java_alternative}.jinfo")).to be_file
    end

    it 'points /etc/alternatives/java to the selected OpenJDK' do
      expect(run_shell("test /etc/alternatives/java -ef #{java_alternative_path}", expect_failures: true).exit_code).to eq(0)
    end

    it_behaves_like 'a configured JAVA_HOME' do
      let(:expected_java_home) { java_home }
    end
  end

  context 'on SLES' do
    before(:each) { skip("not a SLES target (#{os_family})") unless suse? }

    it_behaves_like 'an installed java package' do
      let(:package_name) { java_package_name('jdk') }
    end

    it_behaves_like 'a configured JAVA_HOME' do
      let(:expected_java_home) { java_home }
    end
  end
end
