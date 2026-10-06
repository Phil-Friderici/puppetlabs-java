# frozen_string_literal: true

require 'rspec'
require 'json'

module JavaAcceptanceHelpers
end

require_relative '../../support/acceptance/os_helpers'
require_relative '../../support/acceptance/java_facts_helpers'

describe JavaAcceptanceHelpers::JavaFactsHelpers do
  let(:helper) { Object.new.extend(JavaAcceptanceHelpers::OsHelpers, described_class) }
  let(:public_methods) do
    [
      :default_java_major_version, :java_package_name, :debian_java_architecture,
      :java_alternative, :java_home, :java_alternative_path, :archive_install_supported?,
      :archive_basedir, :java_version_pattern, :java_binary_version, :javac_binary_version,
      :java_facts
    ]
  end

  [
    ['Debian', '13', '21'],
    ['Debian', '26.04', '21'],
    ['Debian', '12', '17'],
    ['Debian', '24.04', '17'],
    ['Debian', '11', '11'],
    ['RedHat', '9', '8'],
    ['RedHat', '10', '21'],
    ['RedHat', '11', '21'],
    ['Suse', '15', '8'],
    ['Other', '10', '8'],
  ].each do |family, release, major|
    context "on #{family} #{release}" do
      before(:each) do
        allow(helper).to receive(:os_facts).and_return('family' => family, 'release' => { 'major' => release }, 'architecture' => 'x86_64')
      end

      it 'preserves the default Java major version' do
        expect(helper.default_java_major_version).to eq(major)
      end
    end
  end

  [
    ['Debian', '12', 'openjdk-17-jdk', 'openjdk-17-jre-headless', '/usr/lib/jvm/java-1.17.0-openjdk-amd64/'],
    ['RedHat', '9', 'java-1.8.0-openjdk-devel', 'java-1.8.0-openjdk', '/usr/lib/jvm/java-1.8.0/'],
    ['RedHat', '10', 'java-21-openjdk-devel', 'java-21-openjdk', '/usr/lib/jvm/java-21-openjdk/'],
    ['Suse', '15', 'java-1_8_0-openjdk-devel', 'java-1_8_0-openjdk', '/usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/'],
    ['Other', '10', 'java-1.8.0-openjdk-devel', 'java-1.8.0-openjdk', '/usr/lib/jvm/java-1.8.0/'],
  ].each do |family, release, jdk, jre, home|
    context "with Java packages on #{family} #{release}" do
      before(:each) do
        allow(helper).to receive(:os_facts).and_return('family' => family, 'release' => { 'major' => release }, 'architecture' => 'x86_64')
      end

      it 'preserves the default JDK package name' do
        expect(helper.java_package_name).to eq(jdk)
      end

      it 'preserves the JRE package name' do
        expect(helper.java_package_name('jre')).to eq(jre)
      end

      it 'uses the JDK package for other distributions' do
        expect(helper.java_package_name('other')).to eq(jdk)
      end

      it 'preserves the Java home' do
        expect(helper.java_home).to eq(home)
      end

      it 'preserves the alternative binary path' do
        expect(helper.java_alternative_path).to eq("#{home}bin/java")
      end
    end
  end

  it 'keeps the existing helper methods public' do
    expect(described_class.public_instance_methods(false)).to match_array(public_methods)
  end

  it 'keeps extracted methods private' do
    expect(described_class.private_instance_methods(false)).to contain_exactly(
      :debian_java_major_version, :redhat_java_package_name, :redhat_java_home
    )
  end

  it 'resolves Java fact names from the parent namespace' do
    stub_const('JavaAcceptanceHelpers::JAVA_FACTS', ['java_version', 'java_major_version'].freeze)
    result = Struct.new(:stdout).new('{"java_version":"17.0.1","java_major_version":"17"}')
    allow(helper).to receive(:target_shell).with('puppet facts show java_version java_major_version --render-as json').and_return(result)

    expect(helper.java_facts).to eq('java_version' => '17.0.1', 'java_major_version' => '17')
  end
end
