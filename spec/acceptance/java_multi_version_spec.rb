# frozen_string_literal: true

require 'spec_helper_acceptance'

# java::adoptium and java::sap install tarballs side by side with the
# system java. Both defines support RedHat and Debian on x86_64 only.
describe 'multiple java versions side by side' do
  adoptium_manifest = <<~MANIFEST
    java::adoptium { 'temurin-17':
      version_major => '17',
      version_minor => '0',
      version_patch => '1',
      version_build => '12',
    }
    java::adoptium { 'temurin-21':
      version_major  => '21',
      version_minor  => '0',
      version_patch  => '4',
      version_build  => '7',
      manage_symlink => true,
      symlink_name   => 'temurin-21',
    }
  MANIFEST

  sap_manifest = <<~MANIFEST
    java::sap { 'sapmachine-jdk-17':
      version      => '17',
      version_full => '17.0.12',
      java         => 'jdk',
    }
    java::sap { 'sapmachine-jre-17':
      version      => '17',
      version_full => '17.0.12',
      java         => 'jre',
    }
  MANIFEST

  context 'with java::adoptium' do
    before(:all) do
      # Cleanup previous runs and check disk space
      shell('rm -rf /tmp/OpenJDK*.tar.gz* /tmp/*.pp 2>/dev/null || true')
      shell('echo "Available space in /tmp:"; df -h /tmp')
      
      apply_manifest(adoptium_manifest, catch_failures: true) if archive_install_supported?
    end

    before(:each) do
      skip("tarball installs are not supported on #{os_family}/#{os_architecture}") unless archive_install_supported?
    end

    it_behaves_like 'an idempotent manifest' do
      let(:manifest) { adoptium_manifest }
    end

    it_behaves_like 'a working java binary' do
      let(:java_bin) { "#{archive_basedir}/jdk-17.0.1+12/bin/java" }
      let(:expected_java_version) { %r{\A17\.0\.1\z} }
    end

    it_behaves_like 'a working java binary' do
      let(:java_bin) { "#{archive_basedir}/jdk-21.0.4+7/bin/java" }
      let(:expected_java_version) { %r{\A21\.0\.4\z} }
    end

    it 'creates the requested symlink' do
      expect(file("#{archive_basedir}/temurin-21")).to be_linked_to("#{archive_basedir}/jdk-21.0.4+7")
    end
  end

  context 'with java::sap' do
    before(:all) do
      # Cleanup previous runs and check disk space
      shell('rm -rf /tmp/sapmachine*.tar.gz* /tmp/*.pp 2>/dev/null || true')
      shell('echo "Available space in /tmp:"; df -h /tmp')
      
      apply_manifest(sap_manifest, catch_failures: true) if archive_install_supported?
    end

    before(:each) do
      skip("tarball installs are not supported on #{os_family}/#{os_architecture}") unless archive_install_supported?
    end

    let(:expected_java_version) { %r{\A17\.0\.12\z} }

    it_behaves_like 'an idempotent manifest' do
      let(:manifest) { sap_manifest }
    end

    it_behaves_like 'a java development kit' do
      let(:javac_bin) { "#{archive_basedir}/sapmachine-jdk-17.0.12/bin/javac" }
    end

    it_behaves_like 'a working java binary' do
      let(:java_bin) { "#{archive_basedir}/sapmachine-jre-17.0.12/bin/java" }
    end
  end

  context 'with the system java' do
    before(:all) do
      apply_manifest(java_class_manifest, catch_failures: true)
    end

    it_behaves_like 'a working java binary' do
      let(:java_bin) { 'java' }
      let(:expected_java_version) { java_version_pattern(default_java_major_version) }
    end
  end
end
