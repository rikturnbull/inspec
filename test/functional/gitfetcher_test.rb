require 'functional/helper'
require 'fileutils'
require 'tmpdir'

describe 'profiles with git-based dependencies' do
  include FunctionalHelper
  before(:all) do
    @tmpdir = Dir.mktmpdir
    @profile_dir = File.join(@tmpdir, 'test-profile')
    @git_dep_dir = File.join(@tmpdir, 'git-dep')
    @deep_git_dep_dir = File.join(@tmpdir, 'deep-git-dep')

    Dir.chdir(@tmpdir) do
      inspec('init profile git-dep')
      inspec('init profile test-profile')

      # InSpec will search directories and execute successfully if there is just
      # one profile. We create two here to ensure we execute both as intended.
      deep_profiles = File.join(@deep_git_dep_dir, 'profiles')
      FileUtils.mkdir_p(deep_profiles)
      inspec('init profile ' + File.join(deep_profiles, 'deep-profile'))
      inspec('init profile ' + File.join(deep_profiles, 'another-deep-profile'))
    end

    Dir.chdir(@git_dep_dir) do
      # Need to overwrite default tests because `/tmp` does not exist in Windows
      File.open(File.join('controls', 'example.rb'), 'w') do |f|
        f.write <<~EOF
          control 'example-1.0' do
            describe 'value' do
              it { should cmp 'value' }
            end
          end
        EOF
      end
      CMD.run_command('git init')
      CMD.run_command('git add .')
      CMD.run_command("git commit -m 'Initial commit' --no-gpg-sign")
      CMD.run_command("git commit -m 'Another commit' --no-gpg-sign")
      CMD.run_command('git tag a_tag')
    end

    Dir.chdir(@deep_git_dep_dir) do
      # Need to overwrite default test because `/tmp` does not exist in Windows
      profile_1 = File.join('profiles', 'deep-profile')
      profile_2 = File.join('profiles', 'another-deep-profile')
      [profile_1, profile_2].each do |profile|
        File.open(File.join(profile, 'controls', 'example.rb'), 'w') do |f|
          f.write <<~EOF
            control '#{File.basename(profile)}-control' do
              describe 'value' do
                it { should cmp 'value' }
              end
            end
          EOF
        end
      end
      CMD.run_command('git init')
      CMD.run_command('git add .')
      CMD.run_command("git commit -m 'Initial commit' --no-gpg-sign")
    end

    File.open(File.join(@profile_dir, 'inspec.yml'), 'a') do |f|
      f.write <<EOF
depends:
  - name: git-dep
    git: #{@git_dep_dir}
    tag: a_tag
  - name: deep-git-dep
    git: #{@deep_git_dep_dir}
    profile_path: 'profiles/deep-profile'
  - name: another-deep-git-dep
    git: #{@deep_git_dep_dir}
    profile_path: 'profiles/another-deep-profile'
EOF
    end

    File.open(File.join(@profile_dir, 'controls', 'example.rb'), 'w') do |f|
      f.write <<~EOF
        include_controls 'git-dep'
        include_controls 'deep-git-dep'
        include_controls 'another-deep-git-dep'
      EOF
    end
  end

  after(:all) do
    FileUtils.rm_rf(@tmpdir)
  end

  it 'executes a profile with a git based dependencies' do
    Dir.mktmpdir do |tmpdir|
      out = inspec("exec #{@profile_dir} " \
                   "--no-create-lockfile " \
                   "--vendor-cache #{tmpdir}")
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
    end
  end
end
