//	author: Benedykt Bela

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <math.h>
#include <time.h>
#include <stdio.h>
#include <stdio.h>

using namespace std;



//		funkcja wykonujaca sie na GPU 
//		argumenty to zadana liczba, dzielnik od ktorego ma sie zaczynac wykonywanie
//		tego wywolania funkcji oraz zmienna czy przyjmujaca wartosc 1 jezeli znalezlismy
//		dzielnik naszej liczby
__global__  void divide(long long int *liczba, int *dzielnik, int *czy)
{
	int i = threadIdx.x + blockIdx.x*blockDim.x;
	//	w kolejnych watkach dzielnik zwiekszam o dwa
	int abc = dzielnik[0] + 2 * i;

	//	jezeli znalezlismy dzielnik, to zmieniamy wartosc zmiennej czy na 1
	if (liczba[0] % abc == 0)
	{
		czy[0] = 1;
	}
}



//	funkca sprawdzajaca czy zadana liczba jest liczba pierwsza bez 
//	korzystania z GPU
int czy_pierwszaCPU(long long int liczba)
{
	//	licze pierwiastek z danej liczby, bo przeszukiwanie dzielnikow wiekszych
	//	jest bezcelowe
	long int pomocnicza = (int)sqrt(liczba);


	//	na poczatku sprawdzam czy liczba to 2 - wtedy zwracam, ze jest to liczba pierwsza
	if (liczba == 2)
	{
		cout << "liczba pierwsza" << endl;
	}
	//	jezeli nie jest to liczba 2, to sprawdzam czy jest parzysta, bo wtedy 
	//	wiadomo, ze jest zlozona
	else if (liczba % 2 == 0)
	{
		cout << "liczba zlozona" << endl;
	}
	//	jezeli nie jest ani dwojka, ani liczba parzysta
	else
	{
		//	dla kazdej nieparzystej liczby wiekszej od 2 i mniejszej od 
		// 	pierwiastka kwadratowego z liczby sprawdzanej
		for (int i = 3; i <= pomocnicza; i += 2)
		{
			//	jezeli i dzieli liczbe przeszukiwana bez reszty, jest to liczba zlozona
			if (liczba % i == 0)
			{
				cout << "liczba zlozona" << endl;

				return 0;
			}
		}

		//	jezeli powyzszy for sprawdzil wszystkie potencjalne dzielniki i nie znalazl
		//	dzielnika, to przeszukiwana liczba jest liczba pierwsza
		cout << "liczba pierwsza" << endl;
	}


	return 0;
}



//	funkcja sprawdzajaca czy zadana liczba jest liczba  pierwsza   
//	korzystajac z GPU
//		nieopisane fragmenty jak w funkcji czy_pierwszaCPU()
int czy_pierwszaGPU(long long int liczba_wczytana)
{
	//	generuje  wskazniki na liczby  przeszukiwane  i zmienna  czy dla CPU i GPU oraz
	//	size - rozmiar long long int'a
	long long int *liczba = new long long int;
	long long int *d_liczba = new long long int;
	int size = sizeof(long long int);
	int *czy = new int;
	int *d_czy = new int;

	//	nasze zaalokowane miejsce przyjmuje wartosc liczby wczytanej
	liczba[0] = liczba_wczytana;

	//	na GPU alokujemy pamiec dla zmiennej czy oraz liczby przeszukiwanej oraz kopiujemy
	//	wartosci tych zmiennych z CPU
	cudaMalloc(&d_czy, sizeof(int));
	cudaMalloc(&d_liczba, size);
	cudaMemcpy(d_liczba, liczba, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_czy, czy, sizeof(int), cudaMemcpyHostToDevice);

	long int pomocnicza = (int)sqrt(*liczba);


	if (liczba[0] == 2)
	{
		cout << "liczba pierwsza" << endl;
	}
	else if (liczba[0] % 2 == 0)
	{
		cout << "liczba zlozona" << endl;
	}
	else
	{
		//	alokacja zmiennej i do iterowania w ponizszej petli for na CPU i GPU
		int *i = new int;
		int *d_i = new int;
		cudaMalloc(&d_i, sizeof(int));
	

		//	dla kazdego nieparzystego i mniejszego od pierwiastka kwadratowego z liczby przeszukiwanej
		for (i[0] = 3; i[0] <= pomocnicza;)
		{
			//	kopiuje wartosc zmiennej i na GPU
			cudaMemcpy(d_i, i, sizeof(int), cudaMemcpyHostToDevice);


			//	w zaleznosci od tego jak duza jest przeszukiwana liczba, a konkretnie jej pierwiastek -
			//	wywoluje funkcje divide wykonywana na GPU z roznymi parametrami
			if (pomocnicza > 100000)
			{
				divide << <2048, 128 >> > (d_liczba, d_i, d_czy);
				//	zwiekszamy poczatkowy indeks przeszukiwan na ostatni przeszukany na GPU
				i[0] += (2048 * 128 * 2);
			}	
			else if (pomocnicza > 10000)
			{
				divide << <256, 32 >> > (d_liczba, d_i, d_czy);
				i[0] += (256 * 32 * 2);
			}
			else if (pomocnicza > 200)
			{
				divide << <2, 32 >> > (d_liczba, d_i, d_czy);
				i[0] += (2 * 32 * 2);
			}
			else
			{
				divide << <1, 1 >> > (d_liczba, d_i, d_czy);
				i[0] += 2;
			}

			//	kopiujemy z GPU wartosc zmiennej czy
			cudaMemcpy(czy, d_czy, sizeof(int), cudaMemcpyDeviceToHost);

			//	jezeli GPU zmienila wartosc zmiennej czy na 1 oznacza to, ze znalazla dzielnik 
			//	liczby przeszukiwanej, wiec liczba jest zlozona i konczymy funkcje
			if (czy[0] == 1)
			{
				cout << "liczba zlozona" << endl;

				return 0;
			}
		}


		cout << "liczba pierwsza" << endl;
	}


	return 0;
}



int main()
{
	//	znak oraz czy jest pomocny przy obsludze funkcji, a liczba to liczba przeszukiwana
	char znak = 'X';
	bool czy = true;
	long long int liczba;


	//	petla wykonuje sie dopoki zmienna czy ma wartosc true, czyli do momentu wpisania 
	//	litery K od koniec jako zmienna wejsciowa
	while (czy)
	{
		//	podajemy przeszukiwana  liczbe
		cout << "Podaj liczbe... " << endl;
		cin >> liczba;

		//	inicjuje zmienne potrzebne do obliczania czasu wykonywania funkcji na GPU i CPU
		double start, end;


		//	mierze czas w chwili startu, wykonuje funkce na CPU, sprawdzam czas w momencie 
		//	zakonczenia funkcji i wyswietlam roznice tych wartosci, czyli czas wykonania funkcji
		start = clock();
		czy_pierwszaCPU(liczba);
		end = clock();
		cout << "Czas wykonania na CPU: " <<end - start << endl;


		//	jak wyzej, tylko dla GPU
		start = clock();
		czy_pierwszaGPU(liczba);
		end = clock();
		cout << "Czas wykonania na GPU: " << end - start << endl << endl;


		//	ponizsza zmienna znak i petla while sluza do obslugi programu:
		//		- jezeli wpiszemy znak 'C' program pyta nas o kolejna liczbe do sprawdzenia
		//		- jezeli wpiszemy znak 'K' program konczy dzialanie
		//		- jezeli wpisany znak jest inny niz K lub C program pyta nas ponownie
		znak = 'X';

		while (znak != 'K' && znak != 'C')
		{
			cout << "to end press K\nto continue press C" << endl;
			cin >> znak;

			if (znak == 'K')
				czy = false;
		}
	}


	return 0;
}
