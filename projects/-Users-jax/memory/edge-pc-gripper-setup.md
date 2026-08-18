---
name: edge-pc-gripper-setup
description: "192.168.0.187 윈도우 미니PC의 DH-Robotics AG 그리퍼 연결 구성 (COM3, Modbus-RTU)"
metadata: 
  node_type: memory
  type: project
  originSessionId: dce2d5b6-71b5-45ad-8a22-1e866ed31057
---

윈도우 미니PC `DESKTOP-7HJD6SU`(192.168.0.187, 계정 `jecs-7200b-i5`, pw 1234, SSH/RDP)에 DH-Robotics AG 시리즈 그리퍼가 연결되어 있다 (2026-07-06 설정).

- 연결: USB-485 컨버터(CH340) → **COM3**, Modbus-RTU **115200 8N1, slave 1**
- CH340 드라이버는 pnputil로 설치됨(`C:\Users\JECS-7200B-i5\ch341drv2\`, oem15.inf)
- 초기화 스크립트: `C:\Users\JECS-7200B-i5\gripper_init.ps1` (포트 탐지→초기화→검증)
- 핵심 레지스터: 초기화 0x0100(1=init, 0xA5=full init), 초기화상태 0x0200, 그리퍼상태 0x0201, 힘 0x0101(20-100%), 위치 0x0103(0-1000‰)
- SSH는 sshd 서비스가 내려가 있을 수 있음 — 안 되면 RDP로 들어가 `Start-Service sshd`
- Mac에서 접속: `sshpass -p 1234 ssh jecs-7200b-i5@192.168.0.187`
- 같은 PC에 Optris Xi 400 열화상 카메라도 연결됨 (sea-thermal-imaging-camera 프로젝트, 상세는 그 repo의 docs/deployment/edge-deployment.md)
