# dst_fc_mod
DST FileCommands mod

��� ������ ������� �� ����� � ������������� � ���� (� �������� �������� 3 ���� � ���).
�������������� �������:
- ���� ������ ������� givePlayer
- ���������� ����\�������
  * spawnNearPlayer - � ������� 6 �� ������ (fab, randomBoss, randomBossLight, randomBossHard)
  * spawnAtPlayer - �� ������� ������� ������ (������������ ��� ������� ���������� � ������)
- ��������� ������� ��� ������ playerCommand (speed, damage, freeze, charge)
- ������� ������� playerEvent/worldEvent
- �������� � ��������� ����� teleportRandom

��� �������, ������� ����� ��������� � ������, ����������� ��� ���� ������� �� �������.
������� ����� ������ � ���� ������ ����� ";".
������ ����������������� ������, ����� ��������� �����, ������� ����������� � �������, 
������ ��� ����� ��������� ����������, � �� ��� ���� �������.

��������� ����:
- Temp\cmd.txt - ������ �� ����� C:\Temp\cmd.txt (�� ��������!!!)
- DST\cmd.txt - ������ �� ����� � ����� � ����� DST\cmd.txt (��� ������� ���� scripts\..?)
- Custom - �������������(!) ���� �������� ��� ��������� ���� � ����

v1.0.0 - �����-����� ���������, ��������� ���
v1.1.0:
- ��� ������� �� ����������, � ��� ��������, �� ����� ���� ���������
- ���� ������� c_annouce, ����� �� ����� ������ � ���������
- ��������� ������� charge
- ��������� 2 ������ ������ 
* randomBoss - ������� �� 1 �� ������� ������
* randomBossLight (����, ��������, �����, �������) �� 1 �� ������� ������
* randomBossHard (�����, ����, �����, �����) - ���������� ���� ������� �� ����� � ����� ������
- ��������� ���������
* ���� D:\cmd.txt
* ������� �� ������� (speed, damage, charge)
* ���������� ������
v1.2.0 - ������������� ���������� ����� randomSpawn, �� �������:
* spawnNearPlayer randomBossLight
* spawnNearPlayer randomBoss
* spawnNearPlayer randomBossHard
* spawnNearPlayer randomTier1
* spawnNearPlayer randomTier2
v1.2.1 - ���� ������� � spawnNearPlayer � ������ �� ������� giveAllRecipes
v1.2.2 - c������ ������� (������ ��� �������� ������) � startApo
v1.2.3 - sleep � ���� �������� ������� + ������
��������, ��� ��� ������������ �������� � �� ������� � �� ������� (�� ������� �� ����� ���� �� �������� � ������ ������, ���� ������� file_path=0)
TODO: ��������� � ��������� ������ ������ �� ������� � �������