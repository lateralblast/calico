#!/usr/bin/env bash

# Name:         calico (Cli for Armbian Linux Image COnfiguration)
# Version:      1.0.8
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          https://github.com/lateralblast/just
# Distribution: UNIX
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  A template for writing shell scripts

# Insert some shellcheck disables
# Depending on your requirements, you may want to add/remove disables
# shellcheck disable=SC2034
# shellcheck disable=SC1090
# shellcheck disable=SC2129

# Create arrays

declare -A os
declare -A flags
declare -A script
declare -A options
declare -A defaults
declare -a options_list
declare -a actions_list

# Grab script information and put it into an associative array

script['args']="$*"
script['file']="$0"
script['name']="calico"
script['file']=$( realpath "${script['file']}" )
script['path']=$( dirname "${script['file']}" )
script['modulepath']="${script['path']}/modules"
script['bin']=$( basename "${script['file']}" )

# Function: set_defaults
#
# Set defaults

set_defaults () {
  flags['board']="BOARD"                                # flag : Board
  flags['branch']="BRANCH"                              # flag : Kernel Branch
  flags['expert']="EXPERT"                              # flag : Expert mode
  flags['release']="RELEASE"                            # flag : Release
  flags['minimal']="BUILD_MINIMAL"                      # flag : Minimal
  flags['desktop']="BUILD_DESKTOP"                      # flag : Desktop
  flags['configure']="KERNEL_CONFIGURE"                 # flag : Configure kernel
  defaults['workdir']="${HOME}/${script['name']}"       # option : Work directory
  defaults['connectwireless']="y"                       # option : Connect to wireless
  defaults['userpassword']="armbian"                    # option : User password
  defaults['rootpassword']="armbian"                    # option : Root password
  defaults['countrycode']="AU"                          # option : Country code
  defaults['container']="ubuntu:latest"                 # option : Container
  defaults['configure']="no"                            # option : Configure kernel
  defaults['mountdir']="/mnt/${script['name']}"         # option : Mount directory
  defaults['builddir']="${defaults['workdir']}/build"   # option : Build directory
  defaults['ethernet']="0"                              # option : Ethernet
  defaults['username']="armbian"                        # option : Username
  defaults['timezone']="Australia/Melbourne"            # option : Timezone
  defaults['realname']="Armbian"                        # option : Real name
  defaults['runtime']="/root/.not_logged_in_yet"        # option : Runtime config file
  defaults['netmask']="255.255.255.0"                   # option : Netmask
  defaults['verbose']="false"                           # option : Verbose mode
  defaults['gateway']=""                                # option : Gateway
  defaults['setlang']="y"                               # option : Set language based on location
  defaults['release']="noble"                           # option : Release
  defaults['minimal']="yes"                             # option : Minimal
  defaults['desktop']="no"                              # option : Desktop
  defaults['default']="false"                           # option : Default mode
  defaults['manual']="false"                            # option : Manual compile
  defaults['locale']="en_AU.UTF-8"                      # option : Locale
  defaults['strict']="false"                            # option : Strict mode
  defaults['import']="false"                            # option : Import mode
  defaults['dryrun']="false"                            # option : Dryrun mode
  defaults['expert']="no"                               # option : Expert mode
  defaults['branch']="current"                          # option : Branch
  defaults['board']=""                                  # option : Board
  defaults['flags']=""                                  # option : Compile flags
  defaults['type']="runtime"                            # option : Configuration type
  defaults['build']="minimal"                           # option : Build
  defaults['debug']="false"                             # option : Debug mode
  defaults['force']="false"                             # option : Force actions
  defaults['ssid']="SSID"                               # option : WiFi SSID
  defaults['shell']="bash"                              # option : User shell
  defaults['wifi']="0"                                  # option : WiFi 
  defaults['full']="false"                              # option : Full path
  defaults['term']="ansi"                               # option : Terminal type
  defaults['mask']="false"                              # option : Mask identifiers
  defaults['dns']="8.8.8.8"                             # option : DNS
  defaults['yes']="false"                               # option : Answer yes to questions
  defaults['key']="KEY"                                 # option : WiFi Key
  defaults['ip']=""                                     # option : IP
  os['name']=$( uname -s )
  if [ "${os['name']}" = "Linux" ]; then
    lsb_check=$( command -v lsb_release )
    if [ -n "${lsb_check}" ]; then 
      os['distro']=$( lsb_release -i -s | sed 's/"//g' )
    else
      os['distro']=$( hostnamectl | grep "Operating System" | awk '{print $3}' )
    fi
  fi
}

set_defaults

# Function: print_message
#
# Print message

print_message () {
  message="$1"
  format="$2"
  if [ "${format}" = "verbose" ]; then
    echo "${message}"
  else
    if [[ "${format}" =~ warn ]]; then
      echo -e "Warning:\t${message}"
    else
      if [ "${options['verbose']}" = "true" ]; then
        if [[ "${format}" =~ ing$ ]]; then
          format="${format^}"
        else
          if [[ "${format}" =~ t$ ]]; then
            if [ "${format}" = "test" ]; then
              format="${format}ing"
            else
              format="${format^}ting"
            fi
          else
            if [[ "${format}" =~ e$ ]]; then
              if [[ ! "${format}" =~ otice ]]; then
                format="${format::-1}"
                format="${format^}ing"
              fi
            fi
          fi
        fi 
        format="${format^}"
        length="${#format}"
        if [ "${length}" -lt 7 ]; then
          tabs="\t\t"
        else
          tabs="\t"
        fi
        echo -e "${format}:${tabs}${message}"
      fi
    fi
  fi
}

# Function: check_package
#
# Check package

check_package () {
  package="$1"
  information_message "Checking package ${package} is installed"
  if [ "${os['name']}" = "Linux" ]; then
    if [ "${os['distro']}" = "Ubuntu" ] || [ "${os['distro']}" = "Debian" ]; then
      package_check=$( dpkg -s "${package}" | grep "^Status: install ok installed" )
      if [ -z "${package_check}" ]; then
        execute_command "apt install ${package} -y" "sudo"
      else
        information_message "Package ${package} is installed"
      fi
    fi
  fi
  if [ "${os['name']}" = "Darwin" ]; then
    package_check=$( brew list | grep "${package}" )
    if [ -z "${package_check}" ]; then
      execute_command "brew install ${package}"
    else
      information_message "Package ${package} is installed"
    fi
  fi
}

# Function: verbose_message
#
# Verbose message

verbose_message () {
  message="$1"
  print_message "${message}" "verbose"
}

# Function: warning_message
#
# Warning message

warning_message () {
  message="$1"
  print_message "${message}" "warn"
}

# Function: execute_message
#
#  Print command

execute_message () {
  message="$1"
  print_message "${message}" "execute"
}

# Function: notice_message
#
# Notice message

notice_message () {
  message="$1"
  print_message "${message}" "notice"
}

# Function: notice_message
#
# Information Message

information_message () {
  message="$1"
  print_message "${message}" "information"
}

# Load modules

if [ -d "${script['modulepath']}" ]; then
  modules=$( find "${script['modulepath']}" -name "*.sh" )
  for module in ${modules}; do
    if [[ "${script['args']}" =~ "verbose" ]]; then
     print_message "Module ${module}" "load"
    fi
    . "${module}"
  done
fi

# Function: reset_defaults
#
# Reset defaults based on command line options

reset_defaults () {
  if [ "${options['firstrun']}" = "" ]; then
    options['firstrun']="${defaults['firstrun']}"
  fi
  if [ "${options['debug']}" = "true" ]; then
    print_message "Enabling debug mode" "notice"
    set -x
  fi
  if [ "${options['strict']}" = "true" ]; then
    print_message "Enabling strict mode" "notice"
    set -u
  fi
  if [ "${options['dryrun']}" = "true" ]; then
    print_message "Enabling dryrun mode" "notice"
  fi
  if [ "${options['minimal']}" = "yes" ]; then
    options['build']="minimal"
    options['desktop']="no"
    options['minimal']="yes"
  fi
  if [ "${options['desktop']}" = "yes" ]; then
    options['build']="desktop"
    options['desktop']="yes"
    options['minimal']="no"
  fi
  if [ "${options['build']}" = "" ]; then
    options['build']="minimal"
    options['desktop']="no"
    options['minimal']="yes"
  fi
  if [ "${options['build']}" = "desktop" ]; then
    options['build']="desktop"
    options['desktop']="yes"
    options['minimal']="no"
  fi
  if [ "${options['build']}" = "minimal" ]; then
    options['build']="minimal"
    options['desktop']="no"
    options['minimal']="yes"
  fi
  for default in "${!defaults[@]}"; do
    if [ "${options[${default}]}" = "" ]; then
      options[${default}]=${defaults[${default}]}
    fi
    information_message "Setting ${default} to ${options[${default}]}"
  done
  defaults['firstrun']="${options['builddir']}/userpatches/extensions/preset-firstrun.sh"
}

# Function: do_exit
#
# Selective exit (don't exit when we're running in dryrun mode)

do_exit () {
  if [ "${options['dryrun']}" = "false" ]; then
    exit
  fi
}

# Function: check_value
#
# check value (make sure that command line arguments that take values have values)

check_value () {
  param="$1"
  value="$2"
  if [[ ${value} =~ ^-- ]]; then
    print_message "Value '$value' for parameter '$param' looks like a parameter" "verbose"
    echo ""
    if [ "${options['force']}" = "false" ]; then
      do_exit
    fi
  else
    if [ "${value}" = "" ]; then
      print_message "No value given for parameter $param" "verbose"
      echo ""
      if [[ "${param}" =~ "option" ]]; then
        print_options
      else
        if [[ "${param}" =~ "action" ]]; then
          print_actions
        else
          print_help
        fi
      fi
      exit
    fi
  fi
}

# Function: execute_command
#
# Execute command

execute_command () {
  command="$1"
  privilege="$2"
  if [[ "${privilege}" =~ su ]]; then
    command="sudo sh -c \"${command}\""
  fi
  if [ "${options['verbose']}" = "true" ]; then
    execute_message "${command}"
  fi
  if [ "${options['dryrun']}" = "false" ]; then
    eval "${command}"
  fi
}

# Function: print_info
#
# Print information

print_info () {
  info="$1"
  echo ""
  echo "Usage: ${script['bin']} --action(s) [action(,action)] --option(s) [option(,option)]"
  echo ""
  if [[ ${info} =~ switch ]]; then
    echo "${info}(es):"
    echo "-----------"
  else
    echo "${info}(s):"
    echo "----------"
  fi
  while read -r line; do
    if [[ "${line}" =~ .*"# ${info}".* ]]; then
      if [[ "${info}" =~ option ]]; then
        IFS=':' read -r param desc <<< "${line}"
        IFS=']' read -r param default <<< "${param}"
        IFS='[' read -r _ param <<< "${param}"
        param="${param//\'/}"
        default="${options[${param}]}"
        if [ "${param}" = "mask" ]; then
          default="false"
        else
          if [ "${options['mask']}" = "true" ]; then
            default="${default/${script['user']}/user}"
          fi
        fi
        param="${param} (default = ${default})"
      else
        IFS='#' read -r param desc <<< "${line}"
        desc="${desc/${info} :/}"
      fi
      echo "${param}"
      echo "  ${desc}"
    fi
  done < "${script['file']}"
  echo ""
}

# Function: print_help
#
# Print help/usage insformation

print_help () {
  print_info "switch"
}

# Function print_actions
#
# Print actions

print_actions () {
  print_info "action"
}

# Function: print_options
#
# Print options

print_options () {
  print_info "option"
}

# Function: print_usage
#
# Print Usage

print_usage () {
  usage="$1"
  case $usage in
    all|full)
      print_help
      print_actions
      print_options
      ;;
    help)
      print_help
      ;;
    action*)
      print_actions
      ;;
    option*)
      print_options
      ;;
    *)
      print_help
      shift
      ;;
  esac
}

# Function: print_version
#
# Print version information

print_version () {
  script['version']=$( grep '^# Version' < "$0" | awk '{print $3}' )
  echo "${script['version']}"
}

# Function: check_shellcheck
#
# Run Shellcheck

check_shellcheck () {
  bin_test=$( command -v shellcheck | grep -c shellcheck )
  if [ ! "$bin_test" = "0" ]; then
    shellcheck "${script['file']}"
  fi
}

# Do some early command line argument processing

if [ "${script['args']}" = "" ]; then
  print_help
  exit
fi

# Function: process_options
#
# Handle options

process_options () {
  option="$1"
  if [[ "${option}" =~ ^no|^un|^dont ]]; then
    options["${option}"]="true"
    if [[ "${option}" =~ ^dont ]]; then
      option="${option:4}"
    else
      option="${option:2}"
    fi
    value="false"
  else
    value="true"
  fi
  options["${option}"]="${value}"
  print_message "${option} to ${value}" "set"
}

# Function: print_environment
#
# Print environment

print_environment () {
  echo "Environment (Options):"
  for option in "${!options[@]}"; do
    value="${options[${option}]}"
    echo -e "Option ${option}\tis set to ${value}"
  done
}

# Function: print_defaults
#
# Print defaults

print_defaults () {
  echo "Defaults:"
  for default in "${!options[@]}"; do
    value="${options[${default}]}"
    echo -e "Default ${default}\tis set to ${value}"
  done
}

# Function: check_packages
#
# Check packages

check_packages () {
  if [ "${os['name']}" = "Linux" ]; then
    for package in qemu-system-arm qemu-system-riscv binfmt-support qemu-user-binfmt; do
      check_package "${package}"
    done
  fi
}

# Function: check_config
#
# Check configuration

check_config () {
  if [ ! -d "${options['workdir']}" ]; then
    warning_message "Work directory ${options['workdir']} does not exist"
    execute_command "mkdir -p ${options['workdir']}"
  fi
  if [ ! -d "${options['builddir']}" ]; then
    warning_message "Build directory ${options['builddir']} does not exist"
    execute_command "cd ${options['workdir']} && git clone https://github.com/armbian/build"
  fi
}

# Function: view_config
#
# View configuration

view_config () {
  if [ ! -f "${defaults['firstrun']}" ]; then
    warning_message "${defaults['firstrun']} does not exist"
    do_exit
  else
    execute_command "cat ${defaults['firstrun']}"
  fi
}

# Function: generate_buildtime_config
#
# Generate buildtime configuration

generate_buildtime_config () {
  check_config
  patches_dir=$( dirname "${defaults['firstrun']}" )
  if [ ! -d "${patches_dir}" ]; then
    information_message "Creating directory ${patches_dir}"
    execute_command "mkdir -p ${patches_dir}"
  fi
  for param in ip netmask gateway dns; do
    if [ "${options[${param}]}" = "" ]; then
      warning_message "${param} is not set"
      do_exit
    fi
  done
  if [ "${options['import']}" = "true" ]; then
    if [ ! -f "${options['firstrun']}" ]; then
      warning_message "Import file ${options['firstrun']} does not exist"
      do_exit
    fi
    execute_command "cp ${options['firstrun']} ${defaults['firstrun']}"
  else
    information_message "Generating ${defaults['firstrun']}"
    tee "${defaults['firstrun']}" << FIRSTRUN
function post_family_tweaks__preset_configs() {
  display_alert "\$BOARD" "preset configs for rootfs" "info"
  # Set PRESET_NET_CHANGE_DEFAULTS to 1 to apply any network related settings below
  echo "PRESET_NET_CHANGE_DEFAULTS=1" > "\${SDCARD}"/root/.not_logged_in_yet

  # Enable WiFi or Ethernet.
  #      NB: If both are enabled, WiFi will take priority and Ethernet will be disabled.
  echo "PRESET_NET_ETHERNET_ENABLED=${options['ethernet']}" >> "\${SDCARD}"/root/.not_logged_in_yet
  echo "PRESET_NET_WIFI_ENABLED=${options['wifi']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  #Enter your WiFi creds
  #      SECURITY WARN: Your wifi keys will be stored in plaintext, no encryption.
  echo "PRESET_NET_WIFI_SSID='${options['ssid']}'" >> "\${SDCARD}"/root/.not_logged_in_yet
  echo "PRESET_NET_WIFI_KEY='${options['key']}'" >> "\${SDCARD}"/root/.not_logged_in_yet

  #      Country code to enable power ratings and channels for your country. eg: GB US DE | https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
  echo "PRESET_NET_WIFI_COUNTRYCODE='${options['countrycode']}'" >> "\${SDCARD}"/root/.not_logged_in_yet

  #If you want to use a static ip, set it here
  echo "PRESET_NET_USE_STATIC=${options['static']}" >> "\${SDCARD}"/root/.not_logged_in_yet
  echo "PRESET_NET_STATIC_IP='${options['ip']}'" >> "\${SDCARD}"/root/.not_logged_in_yet
  echo "PRESET_NET_STATIC_MASK='${options['netmask']}'" >> "\${SDCARD}"/root/.not_logged_in_yet
  echo "PRESET_NET_STATIC_GATEWAY='${options['gateway']}'" >> "\${SDCARD}"/root/.not_logged_in_yet
  echo "PRESET_NET_STATIC_DNS='${options['dns']}'" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Preset user default shell, you can choose bash or  zsh
  echo "PRESET_USER_SHELL=${options['shell']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Set PRESET_CONNECT_WIRELESS=y if you want to connect wifi manually at first login
  echo "PRESET_CONNECT_WIRELESS=${options['connectwireless']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Set SET_LANG_BASED_ON_LOCATION=n if you want to choose "Set user language based on your location?" with "n" at first login
  echo "SET_LANG_BASED_ON_LOCATION=${options['setlang']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Preset default locale
  echo "PRESET_LOCALE=${options['locale']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Preset timezone
  echo "PRESET_TIMEZONE=${options['timezone']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Preset root password
  echo "PRESET_ROOT_PASSWORD=${options['rootpassword']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Preset username
  echo "PRESET_USER_NAME=${options['username']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Preset user password
  echo "PRESET_USER_PASSWORD=${options['userpassword']}" >> "\${SDCARD}"/root/.not_logged_in_yet

  # Preset user default realname
  echo "PRESET_DEFAULT_REALNAME=${options['realname']}" >> "\${SDCARD}"/root/.not_logged_in_yet    
}
FIRSTRUN
  fi
}

# Function: generate_runtime_config
#
# Generate runtime configuration
generate_runtime_config () {
  check_config
  runtime_file="${options['workdir']}${options['runtime']}"
  check_dir=$( dirname "${runtime_file}" )
  if [ ! -d "${check_dir}" ]; then
    execute_command "mkdir -p ${check_dir}"
  fi
  information_message "Generating runtime configuration ${runtime_file}"
  tee "${runtime_file}" << FIRSTRUN
# Set PRESET_NET_CHANGE_DEFAULTS to 1 to apply any network related settings below
PRESET_NET_CHANGE_DEFAULTS=1
# Enable WiFi or Ethernet.
# NB: If both are enabled, WiFi will take priority and Ethernet will be disabled.
PRESET_NET_ETHERNET_ENABLED=${options['ethernet']}
PRESET_NET_WIFI_ENABLED=${options['wifi']}

# Enter your WiFi creds
# SECURITY WARN: Your wifi keys will be stored in plaintext, no encryption.
PRESET_NET_WIFI_SSID='${options['ssid']}'
PRESET_NET_WIFI_KEY='${options['key']}'

# Country code to enable power ratings and channels for your country. eg: GB US DE | https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
PRESET_NET_WIFI_COUNTRYCODE='${options['countrycode']}'

# If you want to use a static ip, set it here
PRESET_NET_USE_STATIC=${options['static']}
PRESET_NET_STATIC_IP='${options['ip']}'
PRESET_NET_STATIC_MASK='${options['netmask']}'
PRESET_NET_STATIC_GATEWAY='${options['gateway']}'
PRESET_NET_STATIC_DNS='${options['dns']}'

# Preset user default shell, you can choose bash or  zsh
PRESET_USER_SHELL=${options['shell']}

# Set PRESET_CONNECT_WIRELESS=y if you want to connect wifi manually at first login
PRESET_CONNECT_WIRELESS=${options['connectwireless']}

# Set SET_LANG_BASED_ON_LOCATION=n if you want to choose "Set user language based on your location?" with "n" at first login
SET_LANG_BASED_ON_LOCATION=${options['setlang']}

# Preset default locale
PRESET_LOCALE=${options['locale']}

# Preset timezone
PRESET_TIMEZONE=${options['timezone']}

# Preset root password
PRESET_ROOT_PASSWORD=${options['rootpassword']}

# Preset username
PRESET_USER_NAME=${options['username']}

# Preset user password
PRESET_USER_PASSWORD=${options['userpassword']}

# Preset user default realname
PRESET_DEFAULT_REALNAME=${options['realname']}
FIRSTRUN
}

# Function: get_compile_flags
#
# Get compile flags
get_compile_flags () {
  for param in "${!flags[@]}"; do
    if [ ! "${options[$param]}" = "" ]; then
      if [ "${options['flags']}" = "" ]; then
        options['flags']="${flags[$param]}=${options[$param]}"
      else
        options['flags']="${options['flags']} ${flags[$param]}=${options[$param]}"
      fi
    fi
  done
}

# Function: compile_image
#
# Compile image

compile_image () {
  check_config
  get_compile_flags
  if [ "${options['manual']}" = "true" ]; then
    execute_command "cd ${options['builddir']} && export TERM=${options['term']} && ./compile.sh"
  else
    if [ "${options['default']}" = "true" ]; then
      execute_command "cd ${options['builddir']} && export TERM=${options['term']} && ./compile.sh ${options['flags']}"
    else
      generate_buildtime_config
      execute_command "export ENABLE_EXTENSIONS=preset-firstrun && cd ${options['builddir']} && export TERM=${options['term']} && ./compile.sh ${options['flags']}"
    fi
  fi
}

# Function: recompile_image
#
# Recompile image

recompile_image () {
  check_config
  get_compile_flags
  if [ -f "${options['firstrun']}" ]; then
    execute_command "export ENABLE_EXTENSIONS=preset-firstrun && cd ${options['builddir']} && export TERM=${options['term']} && ./compile.sh ${options['flags']}"
  else
    warning_message "${options['firstrun']} does not exist"
    do_exit
  fi
}

# Function: list_boards
#
# List boards

list_boards () {
  board_dir="${options['builddir']}/config/boards"
  if [ ! -d "${board_dir}" ]; then
    warning_message "Board directory ${board_dir} does not exist"
    do_exit
  else
    boards=$( ls "${board_dir}" )
    for board in $boards; do
      echo "${board%.*}"
    done
  fi
}

# Function: list_images
#
# List images

list_images () {
  image_dir="${options['builddir']}/output/images"
  if [ ! -d "${image_dir}" ]; then
    warning_message "Image directory ${image_dir} does not exist"
    do_exit
  else
    if [ "${options['full']}" = "true" ]; then
      find "${image_dir}" -name "*.img"
    else
      find "${image_dir}" -name "*.img" -exec basename {} \; 
    fi
  fi
}

# Function: list_items
#
# List items

list_items () {
  case "${options['list']}" in
    board*)
      list_boards
      exit
      ;;
    image*)
      list_images
      exit
      ;;
    *)
      warning_message "Invalid list option: ${options['list']}"
      do_exit
      ;;
  esac
}

# Function: mount image
#
# Mount image

mount_image () {
  if [ "${options['image']}" = "" ]; then
    warning_message "Image not specified"
    do_exit
  fi
  if [ ! -f "${options['image']}" ]; then
    warning_message "Image ${options['image']} does not exist"
    do_exit
  fi
  mount_check=$( mount | grep "${options['mountdir']}" )
  if [ ! "${mount_check}" = "" ]; then
    warning_message "An image is already mounted at ${options['mountdir']}"
    do_exit
  fi
  execute_command "losetup -P -f ${options['image']}" "sudo"
  loop_device=$( losetup -a | grep "${options['image']}" | awk '{print $1}' |cut -f1 -d: )
  if [ ! -d "${options['mountdir']}" ]; then
    execute_command "mkdir -p ${options['mountdir']}" "sudo"
  fi
  execute_command "mount ${loop_device}p1 ${options['mountdir']}" "sudo"
}

# Function: unmount image
#
# Unmount image

unmount_image () {
  if [ "${options['image']}" = "" ]; then
    warning_message "Image not specified"
    do_exit
  fi
  if [ ! -f "${options['image']}" ]; then
    warning_message "Image ${options['image']} does not exist"
    do_exit
  fi
  mount_check=$( mount | grep "${options['mountdir']}" )
  if [ "${mount_check}" = "" ]; then
    warning_message "Image ${options['image']} is not mounted"
    do_exit
  fi
  loop_device=$( losetup -a | grep "${options['image']}" | awk '{print $1}' |cut -f1 -d: )
  execute_command "umount ${options['mountdir']}" "sudo"
  execute_command "losetup -d ${loop_device}" "sudo"
}

# Function: generate_docker_script
#
# Generate docker script

generate_docker_script () {
  if [ "${options['image']}" = "" ]; then
    warning_message "Image not specified"
    do_exit
  fi
  if [ ! -f "${options['image']}" ]; then
    warning_message "Image ${options['image']} does not exist"
    do_exit
  fi
  docker_script="${options['workdir']}/docker.sh"
  information_message "Generating docker script ${docker_script}"
  image_file=$( basename "${options['image']}" )
  image_file="${options['mountdir']}/build/output/images/${image_file}"
  mount_dir="/mnt/imagefs"
  tee "${docker_script}" << DOCKER_SCRIPT
#!/usr/bin/bash
mkdir ${mount_dir}
export IMAGE=${image_file}
export LOOPDEV=\$(losetup --partscan --find --show "\$IMAGE")
lsblk --raw --output "NAME,MAJ:MIN" --noheadings \$LOOPDEV | tail -n +2 | while read dev node;
do
    MAJ=\$(echo \$node | cut -d: -f1)
    MIN=\$(echo \$node | cut -d: -f2)
    [ ! -e "/dev/\$dev" ] &&  mknod "/dev/\$dev" b \$MAJ \$MIN
done
mount \${LOOPDEV}p1 ${mount_dir}
cp ${options['mountdir']}${options['runtime']} ${mount_dir}${options['runtime']}
exit
DOCKER_SCRIPT
  execute_command "chmod +x ${docker_script}"
}

# Function: execute_docker_script
#
# Execute docker script

execute_docker_script () {
  docker_script="${options['mountdir']}/docker.sh"
  execute_command "docker run --privileged -v ${options['workdir']}:${options['mountdir']} -it ${options['container']} ${docker_script}"
}

# Function: generate_config
#
# Generate configuration

generate_config () {
  actions="$1"
  if [[ ${actions} =~ run ]] || [[ ${options['type']} =~ run ]]; then
    generate_runtime_config
  else
    if [[ ${actions} =~ build ]] || [[ ${options['type']} =~ build ]]; then
      generate_buildtime_config
    else
      generate_docker_script
    fi
  fi
}

# Function: modify_image
#
# Modify image

modify_image () {
  if [ "${options['image']}" = "" ]; then
    warning_message "Image not specified"
    do_exit
  fi
  if [ ! -f "${options['image']}" ]; then
    warning_message "Image ${options['image']} does not exist"
    do_exit
  fi
  generate_runtime_config
  if [ "${os['name']}" = "Linux" ]; then
    mount_image
    execute_command "cp ${options['workdir']}${options['runtime']} ${options['mountdir']}${options['runtime']}"
    umount_image
  else
    generate_docker_script
    execute_docker_script
  fi
}

# Function: process_actions
#
# Handle actions

process_actions () {
  actions="$1"
  case $actions in
    compile*)             # action : Compile image
      compile_image
      exit
      ;;
    check*)               # action : Run checks
      check_packages
      check_config
      exit
      ;;
    gen*)                 # action : Generate configuration
      generate_config "${actions}"
      exit
      ;;
    help)                 # action : Print actions help
      print_actions
      exit
      ;;
    list*)                # action : List - e.g. board
      list_items
      exit
      ;;
    modify*)              # action : Modify image
      modify_image
      exit
      ;;
    mount*)               # action : Mount image
      mount_image
      exit
      ;;
    printenv*)            # action : Print environment
      print_environment
      exit
      ;;
    printdefaults)        # action : Print defaults
      print_defaults
      exit
      ;;
    recompile*)           # action : Recompile image - Use existing config
      recompile_image
      exit
      ;;
    shellcheck)           # action : Shellcheck script
      check_shellcheck
      exit
      ;;
    unmount*)             # action : Unmount image
      unmount_image
      exit
      ;;
    version)              # action : Print version
      print_version
      exit
      ;;
    view*)                # action : View configuration
      view_config
      exit
      ;;
    *)
      print_actions
      exit
      ;;
  esac
}

# Handle mask option

if [[ ${script['args']} =~ --option ]] && [[ ${script['args']} =~ mask ]]; then
  options['mask']="true"
fi

# Handle command line arguments

while test $# -gt 0; do
  case $1 in
    --action*)                # switch : Action to perform
      check_value "$1" "$2"
      actions_list+=("$2")
      shift 2
      ;;
    --build)                  # switch : Build
      check_value "$1" "$2"
      options['build']="$2"
      shift 2
      ;;
    --builddir*)              # switch : Build directory
      check_value "$1" "$2"
      options['builddir']="$2"
      shift 2
      ;;
    --board*)                 # switch : Board
      check_value "$1" "$2"
      options['board']="$2"
      shift 2
      ;;
    --branch*)                # switch : Branch
      check_value "$1" "$2"
      options['branch']="$2"
      shift 2
      ;;
    --check*)                 # switch : Run checks
      actions_list+=("check")
      shift
      ;;
    --compile*)               # switch : Compile image
      actions_list+=("compile")
      shift
      ;;
    --config*)                # switch : Configure kernel
      options['configure']="yes"
      shift
      ;;
    --connectwi*)             # switch : Connect to wireless
      options['connectwireless']="yes"
      shift
      ;;
    --container*)             # switch : Container
      check_value "$1" "$2"
      options['container']="$2"
      shift 2
      ;;
    --country*)               # switch : Country code
      check_value "$1" "$2"
      options['countrycode']="$2"
      shift 2
      ;;
    --debug)                  # switch : Enable debug mode
      options['debug']="true"
      shift
      ;;
    --default)                # switch : Enable default build mode
      options['default']="true"
      shift
      ;;
    --desktop)                # switch : Enable desktop mode
      options['desktop']="yes"
      options['minimal']="no"
      shift
      ;;
    --dhcp*)                  # switch : Enable DHCP
      options['static']="0"
      shift
      ;;
    --dns*)                   # switch : DNS Server
      options['static']="1"
      options['ethernet']="1"
      check_value "$1" "$2"
      options['dns']="$2"
      shift 2
      ;;
    --dontconnectwi*)         # switch : Don't connect to wireless
      options['connectwireless']="n"
      shift
      ;; 
    --dontsetlang)            # switch : Don't set language based on location
      options['setlang']="n"
      shift
      ;;
    --dryrun)                 # switch : Enable dryrun mode
      options['dryrun']="true"
      shift
      ;;
    --ethernet)               # switch : Enable Ethernet
      options['ethernet']="1"
      shift
      ;;
    --expert*)                # switch : Expert mode
      options['expert']="yes"
      shift
      ;;
    --firstrun*)              # switch : First run script
      check_value "$1" "$2"
      options['firstrun']="$2"
      shift 2
      ;;
    --flags*)                 # switch : Compile flags
      check_value "$1" "$2"
      options['flags']="$2"
      shift 2
      ;;
    --force)                  # switch : Enable force mode
      options['force']="true"
      shift
      ;;
    --full*)                  # switch : Enable full path mode
      options['full']="true"
      shift
      ;;
    --gateway*)               # switch : Gateway
      options['static']="1"
      options['ethernet']="1"
      check_value "$1" "$2"
      options['gateway']="$2"
      shift 2
      ;;
    --gen*)                   # switch : Generate configuration
      actions_list+=("generate")
      shift
      ;;
    --help|-h)                # switch : Print help information
      print_help
      shift
      exit
      ;;
    --import)                 # switch : Import configuration
      options['import']="true"
      shift
      ;;
    --image*)                 # switch : Image
      check_value "$1" "$2"
      options['image']="$2"
      shift 2
      ;;
    --ip*)                    # switch : IP Address
      options['static']="1"
      options['ethernet']="1"
      check_value "$1" "$2"
      options['ip']="$2"
      shift 2
      ;;
    --key)                    # switch : WiFi key
      check_value "$1" "$2"
      options['key']="$2"
      shift 2
      ;;
    --list)                   # switch : List - e.g. board
      actions_list+=("list")
      check_value "$1" "$2"
      options['list']="$2"
      shift 2
      ;;
    --locale)                 # switch : Locale
      check_value "$1" "$2"
      options['locale']="$2"
      shift 2
      ;;
    --mask)                   # switch : Mask identifiers
      options['mask']="true"
      shift
      ;;
    --modify)                 # switch : Modify image
      actions_list+=("modify")
      shift
      ;;
    --mount|--mountimage)     # switch : Mount image
      actions_list+=("mount")
      shift
      ;;
    --mountdir)               # switch : Mount directory
      check_value "$1" "$2"
      options['mountdir']="$2"
      shift 2
      ;;
    --manual)                 # switch : Manual compile
      options['manual']="true"
      shift
      ;;
    --minimal)                # switch : Enable minimal mode
      options['desktop']="no"
      options['minimal']="yes"
      shift
      ;;
    --netmask*)               # switch : Subnet Mask
      options['static']="1"
      options['ethernet']="1"
      check_value "$1" "$2"
      options['netmask']="$2"
      shift 2
      ;;
    --option*)                # switch : Action to perform
      check_value "$1" "$2"
      options_list+=("$2")
      shift 2
      ;;
    --realname)               # switch : User Real name
      check_value "$1" "$2"
      options['realname']="$2"
      shift 2
      ;;
    --recompile*)             # switch : Recompile image - Use existing config
      actions_list+=("recompile")
      shift
      ;;
    --release*)               # switch : Release
      check_value "$1" "$2"
      options['release']="$2"
      shift 2
      ;;
    --rootpass)               # switch : Root Password
      check_value "$1" "$2"
      options['rootpassword']="$2"
      shift 2
      ;;
    --setlang)                # switch : Set language based on location
      options['setlang']="y"
      shift
      ;;
    --shellcheck)             # switch - Run shellcheck
      actions_list+=("shellcheck")
      shift
      ;;
    --shell)                  # switch : User shell
      check_value "$1" "$2"
      options['shell']="$2"
      shift 2
      ;;
    --ssid)                   # switch : WiFi SSID
      check_value "$1" "$2"
      options['ssid']="$2"
      shift 2
      ;;
    --static*)                # switch : Enable static IP
      options['static']="1"
      shift
      ;;
    --strict)                 # switch : Enable strict mode
      options['strict']="true"
      shift
      ;;
    --term*)                  # switch : Terminal type
      check_value "$1" "$2"
      options['term']="$2"
      shift 2
      ;;
    --timezone)               # switch : Timezone
      check_value "$1" "$2"
      options['timezone']="$2"
      shift 2
      ;;
    --type)                   # switch : Configuration type
      check_value "$1" "$2"
      options['type']="$2"
      shift 2
      ;;
    --unmount*)               # switch : Unmount image
      actions_list+=("unmount")
      shift
      ;;
    --usage)                  # switch : Action to perform
      check_value "$1" "$2"
      usage="$2"
      print_usage "${usage}"
      shift 2
      exit
      ;;
    --username)               # switch : Username
      check_value "$1" "$2"
      options['username']="$2"
      shift 2
      ;;
    --userpass)               # switch : User Password
      check_value "$1" "$2"
      options['userpassword']="$2"
      shift 2
      ;;
    --verbose)                # switch : Enable verbose mode
      options['verbose']="true"
      shift
      ;;
    --version|-V)             # switch : Print version information
      print_version
      exit
      ;;
    --view*)                  # switch - View config
      actions_list+=("view")
      shift
      ;;
    --wifi)                   # switch : Enable WiFi
      options['wifi']="1"
      shift
      ;;
    --workdir)                # switch : Work directory
      check_value "$1" "$2"
      options['workdir']="$2"
      shift 2
      ;;
    *)
      print_help
      shift
      exit
      ;;
  esac
done

# Process options

if [ -n "${options_list[*]}" ]; then
  for list in "${options_list[@]}"; do
    if [[ "${list}" =~ "," ]]; then
      IFS="," read -r -a array <<< "${list[*]}"
      for item in "${array[@]}"; do
        process_options "${item}"
      done
    else
      process_options "${list}"
    fi
  done
fi

# Reset defaults based on switches

reset_defaults

# Process actions

if [ -n "${actions_list[*]}" ]; then
  for list in "${actions_list[@]}"; do
    if [[ "${list}" =~ "," ]]; then
      IFS="," read -r -a array <<< "${list[*]}"
      for item in "${array[@]}"; do
        process_actions "${item}"
      done
    else
      process_actions "${list}"
    fi
  done
fi
