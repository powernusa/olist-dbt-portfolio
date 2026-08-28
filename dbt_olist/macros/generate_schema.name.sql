{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set my_default_schema = target.schema -%}
    
    {%- if custom_schema_name is none -%}
        {{ my_default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}