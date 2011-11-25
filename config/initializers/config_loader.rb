# To change this template, choose Tools | Templates
# and open the template in the editor.

config_file = File.read RAILS_ROOT + "/config/config.yml"
CONFIG = YAML.load(config_file)
