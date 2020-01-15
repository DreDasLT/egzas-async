#include "cuda_runtime.h"
#include <cuda.h>
#include <iostream>
#include "device_launch_parameters.h"
#include <iostream>
#include <fstream>
#include <string>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/reduce.h>
#include <stdio.h>

using namespace std;
using namespace thrust;

const int DUOMENU_KIEKIS = 19;
const int MAX_STRING_ILGIS = 250;

struct Zaidejas
{
public:
	char vardas[MAX_STRING_ILGIS];
	int rungtynes;
	double taskai;
	int pavadinimoIlgis;
};

typedef struct Zaidejas Zaidejas;

struct sumavimas {
	//GPU ir CPU funkcija
	__host__ __device__ Zaidejas operator ()(Zaidejas accumulator, Zaidejas item) 
	{
		int ilgisPavadinimo = 0;
		for (int i = accumulator.pavadinimoIlgis; i < accumulator.pavadinimoIlgis + item.pavadinimoIlgis; i++)
		{
			accumulator.vardas[i] = item.vardas[ilgisPavadinimo];
			ilgisPavadinimo++;
		}
		accumulator.pavadinimoIlgis = accumulator.pavadinimoIlgis + item.pavadinimoIlgis;
		accumulator.rungtynes = accumulator.rungtynes + item.rungtynes;
		accumulator.taskai = accumulator.taskai + item.taskai;

		return accumulator;
	}
};

//skaitymo is failo funkcija
host_vector<Zaidejas> skaityti();

//i faila rasymas
void spausdinti(char vardas[], int rungtynes, double taskai, int pavadinimoIlgis);

int main() {

	//skaitom duomenis
	host_vector<Zaidejas> zaidejai = skaityti();

	//kopinam iš CPU i GPU arba CPU i CPU
	//device_vector<Zaidejas> zaidejai_GPU(zaidejai);//gpu
	host_vector<Zaidejas> zaidejai_GPU(zaidejai);//cpu

	Zaidejas temp;
	temp.pavadinimoIlgis = 0;
	temp.rungtynes = 0;
	temp.taskai = 0.0;

	//funktoriaus panaudojimas
	auto res = reduce(zaidejai_GPU.begin(), zaidejai_GPU.end(), temp, sumavimas());

	for (int j = 0; j < res.pavadinimoIlgis; j++) {
		cout << res.vardas[j];
	}

	cout << " - -> " << res.rungtynes << " - -> " << res.taskai << endl;
	spausdinti(res.vardas, res.rungtynes, res.taskai, res.pavadinimoIlgis);
	return 0;
}

host_vector<Zaidejas> skaityti()
{

	host_vector<Zaidejas> zaidejai(0);
	string nVardas;
	int nRungtynes;
	double nTaskai;
	ifstream fd("duomenys.txt");

	for (int i = 0; i < DUOMENU_KIEKIS; i++) {

		fd >> nVardas >> nRungtynes >> nTaskai;

		Zaidejas temp;
		string vardas = nVardas;
		int rungtynes = nRungtynes;
		double taskai = nTaskai;

		strcpy(temp.vardas, vardas.c_str());
		temp.rungtynes = rungtynes;
		temp.taskai = taskai;
		temp.pavadinimoIlgis = strlen(temp.vardas);

		zaidejai.push_back(temp);
	}
	fd.close();

	return zaidejai;
}

void spausdinti(char vardas[], int rungtynes, double taskai, int pavadinimoIlgis)
{
	ofstream Write;
	Write.open("rezai.txt");

	for (int i = 0; i < pavadinimoIlgis; i++) {
		Write << vardas[i];
	}
	Write << " - -> " << rungtynes << " - -> " << taskai << endl;

	Write.close();
}

