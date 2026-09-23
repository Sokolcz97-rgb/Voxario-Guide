import subprocess,sys
for script in ('fetch_forever_db2.py','normalize_forever_data.py','generate_lua_data.py','validate_generated_data.py'):
 subprocess.run([sys.executable, str(__import__('pathlib').Path(__file__).with_name(script)), *sys.argv[1:]],check=True)
