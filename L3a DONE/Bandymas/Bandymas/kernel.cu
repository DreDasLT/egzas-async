
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>

using namespace std;

const int GIJU_SKAICIUS = 4;
const int DUOMENU_KIEKIS = 19;
const int VIETA = 10;
const int REZULTATU_VIETA = VIETA * (DUOMENU_KIEKIS / GIJU_SKAICIUS);

struct Zaidejas {
public:

	char vardas[REZULTATU_VIETA];
	int rungtynes;
	double taskai;

	//CPU
	//konstruktorius
	__host__ Zaidejas() {
		memset(vardas, ' ', REZULTATU_VIETA);
		rungtynes = 0;
		taskai = 0.0;
	};


	//GPU
	//konstruktorius su parametrais
	__device__ Zaidejas(char vardas[], int rungtynes, double taskai) {
		for (int i = 0; i < REZULTATU_VIETA; i++) {
			this->vardas[i] = vardas[i];
		}
		this->rungtynes = rungtynes;
		this->taskai = taskai;
	}
};

cudaError_t vykdyti(Zaidejas* duomenys, Zaidejas* rezultatai);

__global__ void sumavimas(Zaidejas* zaidejai, Zaidejas* rezultatai);

void skaityti(Zaidejas* zaidejai);

void spausdinti(Zaidejas* duomenys, Zaidejas* rezultatai);


int main()
{
	Zaidejas* zaidejai = new Zaidejas[DUOMENU_KIEKIS];
	skaityti(zaidejai);

	/*
	for (int i = 0; i < DUOMENU_KIEKIS; i++) {
		cout << i << zaidejai[i].pavadinimas << " " << zaidejai[i].metai << " " << zaidejai[i].litrai << endl;
	}
	*/

	Zaidejas* rezultatai = new Zaidejas[GIJU_SKAICIUS];
	cudaError_t cudaStatus = vykdyti(zaidejai, rezultatai);

	spausdinti(zaidejai, rezultatai);

	/*
	cout << "REZAI" << endl;
	for (int i = 0; i < GIJU_SKAICIUS; i++) {
		for (int j = 0; j < REZULTATU_VIETA; j++) {
			cout << rezultatai[i].pavadinimas[j];
		}
		cout << " ->" << rezultatai[i].metai << "-->" << rezultatai[i].litrai << endl;
	}
	*/

	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Klaida kai GPU vykde");
		return 1;
	}

	cudaStatus = cudaDeviceReset();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
		return 1;
	}
	
	delete[] zaidejai;
	delete[] rezultatai;
	return 0;
}



cudaError_t vykdyti(Zaidejas* duomenys, Zaidejas* rezultatai)
{
	cudaError_t cudaStatus;

	//kintamieji skirti GPU darbui
	Zaidejas* gpu_rezultatai = new Zaidejas[GIJU_SKAICIUS];
	Zaidejas* gpu_duomenys = new Zaidejas[DUOMENU_KIEKIS];

	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Nerastas GPU");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)& gpu_duomenys, DUOMENU_KIEKIS * sizeof(Zaidejas));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Klaida isskiriant vieta!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)& gpu_rezultatai, GIJU_SKAICIUS * sizeof(Zaidejas));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}


	//kopijuojam is vienos atminties i kita
	cudaStatus = cudaMemcpy(gpu_duomenys, duomenys, DUOMENU_KIEKIS * sizeof(Zaidejas), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Klaida kopijuojant is CPU i GPU!");
		goto Error;
	}
	cudaStatus = cudaMemcpy(gpu_rezultatai, rezultatai, GIJU_SKAICIUS * sizeof(Zaidejas), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Klaida kopijuojant is CPU i GPU!");
		goto Error;
	}

	//lygiagreti dalis
	sumavimas << <1, GIJU_SKAICIUS >> > (gpu_duomenys, gpu_rezultatai);

	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Ivykusios klaidos: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Klaida grazinta laukiant giju pabaigos: %d\n", cudaStatus);
		goto Error;
	}

	cudaStatus = cudaMemcpy(rezultatai, gpu_rezultatai, GIJU_SKAICIUS * sizeof(Zaidejas), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Klaida kopijuojant is GPU i CPU\n");
		goto Error;
	}
Error:
	cudaFree(gpu_duomenys);
	cudaFree(gpu_rezultatai);

	return cudaStatus;
}

//pagrindinis sumavimas
__global__ void sumavimas(Zaidejas* zaidejai, Zaidejas* rezultatai)
{
	int poKiekImti = DUOMENU_KIEKIS / GIJU_SKAICIUS;
	int gijosNr = threadIdx.x;
	int sumaIki = 0;
	int sumaNuo = 0;
	int z = 0;
	int rungtynes = 0;
	double taskai = 0.0;
	char vardai[REZULTATU_VIETA];

	if (gijosNr == 0) {
		sumaNuo = 0;
		sumaIki = poKiekImti;
	}
	else if (gijosNr == GIJU_SKAICIUS - 1) {
		sumaNuo = gijosNr * poKiekImti;
		sumaIki = DUOMENU_KIEKIS + 1;
	}
	else {
		sumaNuo = gijosNr * poKiekImti;
		sumaIki = (gijosNr + 1) * poKiekImti;
	}

	//printf(" %d--->%d\n", sumaNuo, sumaIki);

	for (int i = sumaNuo; i < sumaIki; i++) {
		rungtynes += (int)zaidejai[i].rungtynes;
		taskai += (double)zaidejai[i].taskai;

		for (int p = 0; p < REZULTATU_VIETA; p++) {
			if (zaidejai[i].vardas[p] != ' ' && zaidejai[i].vardas[p] != '\0') {
				vardai[z] = zaidejai[i].vardas[p];
				z++;
			}
		}
	}

	rezultatai[gijosNr] = Zaidejas(vardai, rungtynes, taskai);
}

//skaitymas is failo
void skaityti(Zaidejas* zaidejai) {

	string zVardas;
	int zRungtynes;
	double zTaskai;
	ifstream fd("duomenys.txt");
	for (int i = 0; i < DUOMENU_KIEKIS; i++) {

		fd >> zVardas >> zRungtynes >> zTaskai;
		strcpy(zaidejai[i].vardas, zVardas.c_str());
		zaidejai[i].taskai = zTaskai;
		zaidejai[i].rungtynes = zRungtynes;
	}
	fd.close();
}

//visko isvedimas i faila
void spausdinti(Zaidejas* duomenys, Zaidejas* rezultatai) {

	ofstream Write("rezultatai.txt");
	Write << "-------->-------Pradiniai duomenys--------<-------" << endl;
	Write << endl;
	Write << "Vardas                                                                 Rungtynes   Taskai" << endl;

	for (int i = 0; i < DUOMENU_KIEKIS; i++) {
		Write << i + 1 << ".) ";
		for (int j = 0; j < REZULTATU_VIETA; j++) {
			Write << duomenys[i].vardas[j];
		}
		Write << "- ->" << duomenys[i].rungtynes << "- ->" << duomenys[i].taskai << endl;
	}
	
	Write << endl;
	Write << endl;
	Write << endl;

	Write << "-------->-------REZULTATAI--------<-------" << endl;
	Write << endl;
	Write << "Vardas                                   Rungtynes   Taskai" << endl;

	for (int i = 0; i < GIJU_SKAICIUS; i++) {
		Write << i + 1 << ".) ";
		for (int j = 0; j < REZULTATU_VIETA; j++) {
			Write << rezultatai[i].vardas[j];
		}
		Write << "- ->" << rezultatai[i].rungtynes << "- ->" << rezultatai[i].taskai << endl;
	}
	Write.close();

}


