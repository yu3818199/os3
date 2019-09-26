// rwdisk.cpp 
//

#include "stdafx.h"
#include "windows.h"
#include "winioctl.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"

/* ͨ��Errorֵƴװ������Ϣ�ַ��� */
static char ErrorMessage[1024];
char* GetErrorString()
{
	HLOCAL LocalAddress=NULL;
	DWORD ErrorCode=0;
	
	memset(ErrorMessage,0,sizeof(ErrorMessage));

	// ȡ������
	ErrorCode= GetLastError();
	FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_IGNORE_INSERTS|FORMAT_MESSAGE_FROM_SYSTEM,  
		NULL,ErrorCode,0,(PTSTR)&LocalAddress,0,NULL);

	// ƴװ�����
	sprintf(ErrorMessage,"[%05d]%s",ErrorCode,(LPSTR)LocalAddress);
	
	// ȥ�س��ͻ���
	if(ErrorMessage[strlen(ErrorMessage)-1]==0x0a || ErrorMessage[strlen(ErrorMessage)-1]==0x0d)
		ErrorMessage[strlen(ErrorMessage)-1]=0;
	if(ErrorMessage[strlen(ErrorMessage)-1]==0x0a || ErrorMessage[strlen(ErrorMessage)-1]==0x0d)
		ErrorMessage[strlen(ErrorMessage)-1]=0;

    return ErrorMessage;  

}

/* ����Ļ�ϴ�ӡbuf���� */
void display(unsigned char *buf,int size)
{
	char hex[100],asc[100];

	for(int i=0;i<size/16+1;i++)
	{
		memset(hex,0,sizeof(hex));
		memset(asc,0,sizeof(asc));

		for(int j=0;j<16;j++)
		{
			if(i*16+j+1>size)
			{
				break;
			}
			// ��ӡ16����
			sprintf(hex,"%s %02X",hex,buf[i*16+j]);
			// ��ӡ�ɼ��ַ�
			if(buf[i*16+j]>0x20 && buf[i*16+j]<0x7e)
				sprintf(asc,"%s%c",asc,buf[i*16+j]);
			else
				sprintf(asc,"%s%c",asc,' ');
		}
		if(hex[0]!=0)
			printf("%05X %s %s\n",i*16,hex,asc);
		if((i+1)%32==0 && i!=0)
			printf("-----------------------------------------------------------------------\n");
	}

}


/* ���ش������� */
double getdisksize_gb(HANDLE hDev)
{

	DWORD BytesReturned;
	GET_MEDIA_TYPES media_types;

	if(DeviceIoControl(hDev,IOCTL_STORAGE_GET_MEDIA_TYPES_EX,NULL,NULL,&media_types,sizeof(media_types),&BytesReturned,(LPOVERLAPPED)NULL)==0)
	{
		printf("DeviceIoControl=[%s]\n",GetErrorString());
		return -1;
	}

	/* ������ */
	double Cylinders=(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.Cylinders.HighPart * 256 * 256 * 256 + 
		(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.Cylinders.LowPart;
	/* ÿ����ŵ��� */
	double TracksPerCylinder=(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.TracksPerCylinder;
	/* ÿ���������� */
	double SectorsPerTrack=(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.SectorsPerTrack;
	/* ÿ�����ֽ��� */
	double BytesPerSector=(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.BytesPerSector;

	/* ���ش�������(GB) */
	return Cylinders*TracksPerCylinder*SectorsPerTrack*BytesPerSector/1024/1024/1024;

}

// �Դ����������ݵĶ�ȡ
BOOL ReadSectors (BYTE bDrive, DWORD dwStartSector, DWORD dwSectors, LPBYTE lpSectBuff)
{
	if (bDrive == 0) return 0;
	char devName[] = "\\\\.\\PhysicalDrive1";
	devName[17]=bDrive;

	// �򿪴���
	HANDLE hDev = CreateFile(devName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, NULL);
	if (hDev == INVALID_HANDLE_VALUE){
		printf("CreateFile devName=[%s] ErrorMsg=[%s]\n",devName,GetErrorString());
		return FALSE;
	}

	// ��ȡ����
	SetFilePointer(hDev, 512 * dwStartSector, 0, FILE_BEGIN);
	DWORD dwCB;
	if(ReadFile(hDev, lpSectBuff, 512 * dwSectors, &dwCB, NULL)==0)
	{
		printf("ReadSectors ErrorMsg=[%s]\n",GetErrorString());
		return FALSE;
	}

	CloseHandle(hDev);

	return TRUE;
}

// �Դ����������ݵ�д��
BOOL WriteSectors(BYTE bDrive, DWORD dwStartSector, DWORD dwSectors, LPBYTE lpSectBuff)
{
	if (bDrive == 0) return 0;
	char devName[] = "\\\\.\\PhysicalDrive1";
	devName[17]=bDrive;

	// �򿪴���
	HANDLE hDev = CreateFile(devName, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, NULL);
	if (hDev == INVALID_HANDLE_VALUE){
		printf("CreateFile devName=[%s] ErrorMsg=[%s]\n",devName,GetErrorString());
		return FALSE;
	}

	if(getdisksize_gb(hDev)>16)
	{
		printf("������������16G��������д��\n");		
		CloseHandle(hDev);
		return FALSE;
	}

	// ��ʾ��������
	printf("׼��д�����[%s],����%0.1lfGB,��%d������ʼд��%d������,�Ƿ����?[Y/N]",devName,getdisksize_gb(hDev),dwStartSector,dwSectors);
	char get_ch=getchar();
	if(get_ch!='Y' && get_ch!='y')
	{
		CloseHandle(hDev);
		return FALSE;
	}

	// д������
	SetFilePointer(hDev, 512 * dwStartSector, 0, FILE_BEGIN);
	DWORD dwCB;
	if(WriteFile(hDev, lpSectBuff, 512 * dwSectors, &dwCB, NULL)==0)
	{
		printf("WriteSectors ErrorMsg=[%s]\n",GetErrorString());
		return FALSE;
	}

	CloseHandle(hDev);

	return TRUE;
}

/* ��ȡ�ļ������������� */
BOOL ReadFile(char *filename,char *readbuf,unsigned int size)
{
	FILE *fp;
	if((fp=fopen(filename,"rb"))==NULL)
	{
		printf("fopen filename=[%s] ErrorMsg=[%s]\n",filename,GetErrorString());
		return FALSE;
	}
	if(fread(readbuf,1,size,fp)!=size)
	{
		printf("fread �ļ����ݲ��� filename=[%s] size=[%d]\n",filename,size);
		fclose(fp);
		return FALSE;
	}
	fclose(fp);
	return TRUE;
}

/* ���������ݱ������ļ��� */
BOOL WriteFile(char *filename,char *readbuf,unsigned int size)
{
	FILE *fp;
	if((fp=fopen(filename,"wb+"))==NULL)
	{
		printf("fopen filename=[%s] ErrorMsg=[%s]\n",filename,GetErrorString());
		return FALSE;
	}
	if(fwrite(readbuf,1,size,fp)!=size)
	{
		printf("fwrite �ļ����ݲ��� filename=[%s] size=[%d]\n",filename,size);
		fclose(fp);
		return FALSE;
	}
	fclose(fp);
	return TRUE;
}

#define MSG_DISPLAY "��ӡ: rwdisk display [��ȡ���̺�] [��ʼ����] [��ȡ������]"
#define MSG_READ    "��ȡ: rwdisk read    [��ȡ���̺�] [��ʼ����] [��ȡ������] [д���ļ���]"
#define MSG_WRITE   "д��: rwdisk write   [д����̺�] [��ʼ����] [д��������] [��ȡ�ļ���]"

/* ������ */
int main(int argc, char* argv[])
{

	BYTE *readbuff;
	char sFilename[1024];
	BYTE bDrive;
	DWORD StartSectors;
	DWORD Sectors;

	printf("Ӳ��������ȡд�빤�� @2019\n");

	if(argc<2)
	{
		printf("%s\n%s\n%s\n",MSG_DISPLAY,MSG_READ,MSG_WRITE);
		return -1;
	}
	if(strcmp(argv[1],"display")!=0 &&
		strcmp(argv[1],"write")!=0 &&
		strcmp(argv[1],"read")!=0
		)
	{
		printf("%s\n%s\n%s\n",MSG_DISPLAY,MSG_READ,MSG_WRITE);
		return -1;
	}

	if(strcmp(argv[1],"display")==0)
	{
		if(argc!=5)
		{
			printf("%s\n",MSG_DISPLAY);
			return -1;
		}
		bDrive=argv[2][0];
		StartSectors=atoi(argv[3]);
		Sectors=atoi(argv[4]);
		if(bDrive<'0' || bDrive>'9')
		{
			printf("���̺�����\n");
			return -1;
		}
		if(StartSectors<0)
		{
			printf("��ʼ��������С��0\n");
			return -1;
		}
		if(Sectors==0)
		{
			printf("����������Ϊ0\n");
			return -1;
		}

		printf("��ȡ����%c����%d������ʼ��ȡ%d���� \n",bDrive,StartSectors,Sectors);

		readbuff=(BYTE *)malloc(Sectors*512);
		if(readbuff==NULL)
		{
			printf("�ڴ����ʧ��\n");
			return -1;
		}

		/* ��ȡ�������� */
		if(ReadSectors(bDrive, StartSectors, Sectors, readbuff)==FALSE) {
			return -1;
		}

		display(readbuff,Sectors*512);

		free(readbuff);

		return 0;

	}


	if(strcmp(argv[1],"read")==0)
	{
		if(argc!=6)
		{
			printf("%s\n",MSG_READ);
			return -1;
		}
		bDrive=argv[2][0];
		StartSectors=atoi(argv[3]);
		Sectors=atoi(argv[4]);
		strcpy(sFilename,argv[5]);
		if(bDrive<'0' || bDrive>'9')
		{
			printf("���̺�����\n");
			return -1;
		}
		if(StartSectors<0)
		{
			printf("��ʼ��������С��0\n");
			return -1;
		}
		if(Sectors==0)
		{
			printf("����������Ϊ0\n");
			return -1;
		}

		printf("��ȡ����%c����%d������ʼ��ȡ%d������д��%s�ļ�\n",bDrive,StartSectors,Sectors,sFilename);

		readbuff=(BYTE *)malloc(Sectors*512);
		if(readbuff==NULL)
		{
			printf("�ڴ����ʧ��\n");
			return -1;
		}

		/* ��ȡ�������� */
		if(ReadSectors(bDrive, StartSectors, Sectors, readbuff)==FALSE) {
			return -1;
		}

		if(WriteFile(sFilename,(char *)readbuff,Sectors*512)==FALSE) {
			return -1;
		}

		printf("д���ļ��ɹ�\n");

		free(readbuff);

		return 0;

	}


	if(strcmp(argv[1],"write")==0)
	{
		if(argc!=6)
		{
			printf("%s\n",MSG_WRITE);
			return -1;
		}
		bDrive=argv[2][0];
		StartSectors=atoi(argv[3]);
		Sectors=atoi(argv[4]);
		strcpy(sFilename,argv[5]);
		if(bDrive=='0')
		{
			printf("0������ϵͳ�̣�������д��0����\n");
			return -1;
		}
		if(bDrive<'1' || bDrive>'9')
		{
			printf("���̺�����\n");
			return -1;
		}
		if(StartSectors<0)
		{
			printf("��ʼ��������С��0\n");
			return -1;
		}
		if(Sectors==0)
		{
			printf("����������Ϊ0\n");
			return -1;
		}

		printf("��ȡ%s�ļ���д�����%c����%d������ʼд��%d������\n",sFilename,bDrive,StartSectors,Sectors);

		readbuff=(BYTE *)malloc(Sectors*512);
		if(readbuff==NULL)
		{
			printf("�ڴ����ʧ��\n");
			return -1;
		}

		/* ��ȡ�������ݲ����� */
		if(ReadSectors(bDrive, StartSectors, Sectors, readbuff)==FALSE) {
			return -1;
		}
		if(WriteFile("Sectors.bak",(char *)readbuff,Sectors*512)==FALSE) {
			return -1;
		}

		/* ��ȡ�ļ����� */
		if(ReadFile(sFilename,(char *)readbuff,Sectors*512)==FALSE) {
			return -1;
		}

		/* д������ */
		if(WriteSectors(bDrive, StartSectors, Sectors, readbuff)==FALSE) {
			return -1;
		}

		printf("д����̳ɹ�\n");

		free(readbuff);

		return 0;

	}



	return 0;

}


