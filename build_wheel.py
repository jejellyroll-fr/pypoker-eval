#!/usr/bin/env python3
"""
Universal wheel build script for pypoker-eval
Compatible with both standard Python and uv
"""

import os
import sys
import shutil
import zipfile
import tempfile
import subprocess
from pathlib import Path

def detect_python_manager():
    """Detect if we're using uv or standard Python"""
    # Check if uv is available
    try:
        result = subprocess.run(['uv', '--version'], 
                              capture_output=True, text=True, check=True)
        print(f"✅ uv detected: {result.stdout.strip()}")
        return 'uv'
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("⚠️  uv not available, using standard Python")
        return 'python'

def get_python_info():
    """Get current Python information"""
    version = f"{sys.version_info.major}.{sys.version_info.minor}"
    version_short = f"{sys.version_info.major}{sys.version_info.minor}"
    
    # Expected extension name
    if sys.platform.startswith('win'):
        ext_name = f"_pokereval_{version_short}.pyd"
        platform_tag = "win_amd64"
    elif sys.platform.startswith('darwin'):
        ext_name = f"_pokereval_{version_short}.so"
        if 'arm64' in os.uname().machine.lower():
            platform_tag = "macosx_11_0_arm64"
        else:
            platform_tag = "macosx_10_15_x86_64"
    else:  # Linux
        ext_name = f"_pokereval_{version_short}.so"
        platform_tag = "linux_x86_64"
    
    return version, version_short, ext_name, platform_tag

def build_with_cmake(python_manager, python_version):
    """Build extension with CMake"""
    print(f"🔨 Building with {python_manager} Python {python_version}...")
    
    # Clean previous build
    if os.path.exists('build'):
        shutil.rmtree('build')
    os.makedirs('build')
    
    # Build poker-eval first
    print("📦 Building poker-eval...")
    subprocess.run(['git', 'submodule', 'update', '--init', '--recursive'], check=True)
    
    poker_eval_build = Path('poker-eval/build')
    poker_eval_build.mkdir(exist_ok=True)
    
    os.chdir('poker-eval/build')
    subprocess.run(['cmake', '..', '-DCMAKE_POSITION_INDEPENDENT_CODE=ON'], check=True)
    subprocess.run(['cmake', '--build', '.'], check=True)
    os.chdir('../..')
    
    # Build pypoker-eval
    print("🐍 Building pypoker-eval...")
    os.chdir('build')
    
    if python_manager == 'uv':
        # Use uv Python if available
        python_exe = subprocess.run(['uv', 'run', f'--python', python_version, 'which', 'python'], 
                                  capture_output=True, text=True, check=True).stdout.strip()
    else:
        # Use current Python
        python_exe = sys.executable
    
    print(f"🎯 Using Python: {python_exe}")
    
    # CMake will automatically configure the right Python thanks to our modified CMakeLists.txt
    subprocess.run(['cmake', '..'], check=True)
    subprocess.run(['cmake', '--build', '.'], check=True)
    
    os.chdir('..')
    return True

def create_wheel(python_version, version_short, ext_name, platform_tag):
    """Create wheel with compiled extension"""
    print(f"🎡 Creating wheel for {ext_name}...")
    
    # Find compiled extension
    possible_extensions = [
        f'build/{ext_name}',
        f'build/pypokereval.so',
        f'build/pypokereval.pyd',
        f'build/Release/pypokereval.pyd',
        f'build/Debug/pypokereval.pyd'
    ]
    
    extension_file = None
    for ext_path in possible_extensions:
        if os.path.exists(ext_path):
            extension_file = ext_path
            break
    
    if not extension_file:
        print("❌ Compiled extension not found!")
        return False
    
    print(f"📁 Extension found: {extension_file}")
    
    # Copy with correct name
    target_ext = f"_pokereval_{version_short}"
    if sys.platform.startswith('win'):
        target_ext += ".pyd"
    else:
        target_ext += ".so"
    
    shutil.copy2(extension_file, target_ext)
    
    # Wheel version
    wheel_version = f"3.{python_version.replace('.', '')}.0"
    
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        
        # Copy files
        shutil.copy2('pokereval.py', temp_path / 'pokereval.py')
        shutil.copy2(target_ext, temp_path / target_ext)
        
        # Create metadata
        metadata_dir = temp_path / f'pypoker_eval-{wheel_version}.dist-info'
        metadata_dir.mkdir()
        
        # METADATA
        with open(metadata_dir / 'METADATA', 'w') as f:
            f.write(f"""Metadata-Version: 2.1
Name: pypoker-eval
Version: {wheel_version}
Summary: Python poker hand evaluator (uv compatible)
Author: pypoker-eval
License: GPL-2.0+
Platform: {platform_tag}
Classifier: Development Status :: 4 - Beta
Classifier: Programming Language :: Python :: {python_version}
Requires-Python: >={python_version}
""")
        
        # WHEEL
        with open(metadata_dir / 'WHEEL', 'w') as f:
            f.write(f"""Wheel-Version: 1.0
Generator: build_wheel.py
Root-Is-Purelib: false
Tag: py3-none-any
""")
        
        # top_level.txt
        with open(metadata_dir / 'top_level.txt', 'w') as f:
            f.write('pokereval\n')
        
        # RECORD
        with open(metadata_dir / 'RECORD', 'w') as f:
            f.write(f"""pokereval.py,,
{target_ext},,
pypoker_eval-{wheel_version}.dist-info/METADATA,,
pypoker_eval-{wheel_version}.dist-info/WHEEL,,
pypoker_eval-{wheel_version}.dist-info/top_level.txt,,
pypoker_eval-{wheel_version}.dist-info/RECORD,,
""")
        
        # Create wheel
        os.makedirs('dist', exist_ok=True)
        wheel_name = f'pypoker_eval-{wheel_version}-py3-none-any.whl'
        wheel_path = f'dist/{wheel_name}'
        
        with zipfile.ZipFile(wheel_path, 'w', zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(temp_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    arc_name = os.path.relpath(file_path, temp_path)
                    zf.write(file_path, arc_name)
        
        print(f"✅ Wheel created: {wheel_path}")
        return wheel_path

def main():
    print("🚀 PyPoker-Eval Wheel Builder")
    print("=" * 40)
    
    # Detect environment
    python_manager = detect_python_manager()
    python_version, version_short, ext_name, platform_tag = get_python_info()
    
    print(f"📋 Configuration:")
    print(f"   • Manager: {python_manager}")
    print(f"   • Python: {python_version}")
    print(f"   • Extension: {ext_name}")
    print(f"   • Platform: {platform_tag}")
    print()
    
    # Build
    if not build_with_cmake(python_manager, python_version):
        sys.exit(1)
    
    # Create wheel
    wheel_path = create_wheel(python_version, version_short, ext_name, platform_tag)
    if not wheel_path:
        sys.exit(1)
    
    print(f"\n🎉 Success! Wheel available: {wheel_path}")
    
    # Quick test if possible
    if python_manager == 'uv':
        print("\n🧪 Quick test with uv...")
        try:
            subprocess.run(['uv', 'pip', 'install', wheel_path, '--force-reinstall'], 
                         check=True, capture_output=True)
            result = subprocess.run(['uv', 'run', '--python', python_version, 
                                   'python', '-c', 'import pokereval; print("✅ Import OK!")'], 
                                  capture_output=True, text=True, check=True)
            print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"⚠️  Quick test failed: {e}")

if __name__ == "__main__":
    main()