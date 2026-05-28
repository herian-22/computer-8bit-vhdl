@echo off
setlocal
cd /d "%~dp0\.."

if not exist sim mkdir sim

echo [1/3] Analyzing VHDL sources...
ghdl -a src/cpu/alu.vhd ^
      src/mem/rom_128x8_sync.vhd ^
      src/mem/rw_96x8_sync.vhd ^
      src/mem/memory_system.vhd ^
      src/cpu/data_path.vhd ^
      src/cpu/control_unit.vhd ^
      src/cpu/cpu.vhd ^
      src/top/computer_top.vhd ^
      tb/tb_computer.vhd
if errorlevel 1 goto :error

echo [2/3] Elaborating...
ghdl -e tb_computer
if errorlevel 1 goto :error

echo [3/3] Running simulation...
ghdl -r tb_computer --wave=sim/wave.ghw --stop-time=13us
if errorlevel 1 (
  echo Simulation ended (check results above)
)

echo.
echo Opening GTKWave...
start "" "C:\msys64\ucrt64\bin\gtkwave.exe" sim\wave.ghw

goto :end

:error
echo.
echo BUILD FAILED
exit /b 1

:end
echo Done.
