# Home Assistant Templates
# Common configuration templates for Home Assistant development

## Automation Templates

### Basic Automation Template
```yaml
- id: template_basic_automation
  alias: "Template: Basic Automation"
  description: "Template for basic automation with trigger, condition, and action"
  trigger:
    - platform: state
      entity_id: sensor.example_sensor
      to: "on"
  condition:
    - condition: state
      entity_id: binary_sensor.example_condition
      state: "on"
  action:
    - service: notify.example_notification
      data:
        title: "Automation Triggered"
        message: "Basic automation executed"
```

### Time-Based Automation Template
```yaml
- id: template_time_automation
  alias: "Template: Time-Based Automation"
  description: "Template for time-based automation"
  trigger:
    - platform: time
      at: "08:00:00"
  action:
    - service: script.example_morning_routine
```

### Device State Automation Template
```yaml
- id: template_device_state_automation
  alias: "Template: Device State Automation"
  description: "Template for device state changes"
  trigger:
    - platform: state
      entity_id: media_player.example_device
      from: "off"
      to: "on"
  action:
    - service: media_player.volume_set
      target:
        entity_id: media_player.example_device
      data:
        volume_level: 0.5
```

## Script Templates

### Basic Script Template
```yaml
template_basic_script:
  alias: "Template: Basic Script"
  description: "Template for basic script"
  sequence:
    - service: notify.example_notification
      data:
        title: "Script Executed"
        message: "Basic script completed"
```

### Conditional Script Template
```yaml
template_conditional_script:
  alias: "Template: Conditional Script"
  description: "Template for conditional script"
  sequence:
    - if:
        - condition: state
          entity_id: binary_sensor.example_condition
          state: "on"
      then:
        - service: script.example_action
      else:
        - service: script.example_alternative_action
```

### Loop Script Template
```yaml
template_loop_script:
  alias: "Template: Loop Script"
  description: "Template for script with loops"
  sequence:
    - repeat:
        count: 3
        sequence:
          - service: notify.example_notification
            data:
              message: "Loop iteration {{ repeat.index }}"
          - delay: "00:00:01"
```

## Group Templates

### Device Group Template
```yaml
template_device_group:
  name: "Template Device Group"
  entities:
    - sensor.example_sensor_1
    - sensor.example_sensor_2
    - binary_sensor.example_binary_sensor
  icon: mdi:template
```

### Control Group Template
```yaml
template_control_group:
  name: "Template Control Group"
  entities:
    - script.template_basic_script
    - script.template_conditional_script
    - input_select.example_input
    - input_number.example_number
  icon: mdi:remote
```

## Scene Templates

### Basic Scene Template
```yaml
template_basic_scene:
  name: "Template Basic Scene"
  entities:
    light.example_light:
      state: "on"
      brightness: 255
      color_name: "white"
  icon: mdi:lightbulb
```

### Multi-Device Scene Template
```yaml
template_multi_device_scene:
  name: "Template Multi-Device Scene"
  entities:
    light.example_light:
      state: "on"
      brightness: 128
    media_player.example_player:
      state: "on"
      volume_level: 0.3
    input_select.example_input:
      option: "Option 1"
  icon: mdi:home-automation
```

## Integration Templates

### LG webOS TV Template
```yaml
webostv:
  - host: 192.168.0.39
    name: "LG C5 Monitor"
    turn_on_action:
      - service: wake_on_lan.send_magic_packet
        data:
          mac: "58:96:0a:c3:1g:5b"
    turn_off_action:
      - service: webostv.turn_off
        target:
          entity_id: media_player.lg_c5_monitor
```

### macOS Integration Template
```yaml
ios:
  push:
    categories:
      - name: "Example Category"
        identifier: example_category
        actions:
          - identifier: ACTION_1
            title: "Action 1"
          - identifier: ACTION_2
            title: "Action 2"
```

## Input Templates

### Input Select Template
```yaml
input_select:
  example_input_select:
    name: "Example Input Select"
    options:
      - "Option 1"
      - "Option 2"
      - "Option 3"
    initial: "Option 1"
    icon: mdi:format-list-bulleted
```

### Input Number Template
```yaml
input_number:
  example_input_number:
    name: "Example Input Number"
    min: 0
    max: 100
    step: 1
    initial: 50
    icon: mdi:counter
```

### Input Boolean Template
```yaml
input_boolean:
  example_input_boolean:
    name: "Example Input Boolean"
    initial: false
    icon: mdi:toggle-switch
```

## Sensor Templates

### Template Sensor Template
```yaml
sensor:
  - platform: template
    sensors:
      example_template_sensor:
        friendly_name: "Example Template Sensor"
        value_template: "{{ states('sensor.example_sensor') | float * 2 }}"
        unit_of_measurement: "°C"
        icon_template: "mdi:thermometer"
```

### Binary Sensor Template
```yaml
binary_sensor:
  - platform: template
    sensors:
      example_template_binary_sensor:
        friendly_name: "Example Template Binary Sensor"
        value_template: "{{ is_state('sensor.example_sensor', 'on') }}"
        icon_template: "mdi:power"
```

## Usage Instructions

1. **Copy Templates**: Copy the relevant template to your configuration file
2. **Customize**: Replace example values with your actual device names and settings
3. **Validate**: Use `./bin/ha-validate` to check for syntax errors
4. **Test**: Deploy and test the configuration
5. **Document**: Add descriptions and comments to explain the configuration

## Best Practices

- Always use descriptive names and aliases
- Include proper descriptions for complex configurations
- Use templates for repeated patterns
- Test configurations thoroughly before deploying
- Keep configurations modular and organized
- Use secrets for sensitive information
- Document complex logic and dependencies
