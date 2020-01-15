/*
1. Programos pradiniai duomenys - masyvas su visais sveikaisiais skaičiais nuo 0 iki 999 iš eilės imtinai. Išdalinti elementus po lygiai 10 procesų (nuo 0 iki 99 elemento, nuo 100 iki 199 ir t.t.).
    Kiekvienas gija randa savo dalies vidurkį (float tipo) ir persiunčia pagrindiniam procesui. Gauti vidurkiai išvedami ekrane. Realizuoti naudojantis GO kanalais arba MPI.

2. Modifikuokite programą, kad kiekvienas procesas surastų savo duomenų dalies sumą, ją persiųstų papildomam sumavimo procesui, kuris suranda jam siunčiamų dalinių sumų sumą ir persiunčia pagrindiniam procesui.
    Gaitas rezultatas išvedamas ekrane.
*/

#include <iostream>
#include <mpi.h>

using namespace std;
using namespace MPI;

int main()
{
    MPI::Init();
    int size = MPI::COMM_WORLD.Get_size();
    auto rank = MPI::COMM_WORLD.Get_rank();
    auto totalProcesses = MPI::COMM_WORLD.Get_size();
    if (rank == 0)
    {
        int worker_count = 10;
        const auto DATA_SIZE = 1000;
        int numbers[DATA_SIZE];
        for (int i = 0; i < 1000; i++)
        {
            numbers[i] = i;
        }
        auto chunk_size = 100;
        for (auto i = 0; i < worker_count; i++)
        {
            int start_index = i * chunk_size;
            COMM_WORLD.Send(numbers + start_index, 100, INT, i + 2, 2);
        }
        for (auto i = 0; i < worker_count; i++)
        {
            MPI_Status status;
            float avg;
            MPI_Recv(&avg, 1, FLOAT, MPI_ANY_SOURCE, 1, COMM_WORLD, &status);
            cout << avg << endl;
        }
        MPI_Status status;
        int sumSum;
        MPI_Recv(&sumSum, 1, INT, 1, 3, COMM_WORLD, &status);
        cout << "Dalines sumos - " << sumSum << endl;
    }
    else if (rank == 1)
    {
        MPI_Status status;
        int sum = 0;
        int temp = 0;
        for (int i = 0; i < totalProcesses - 2; i++)
        {
            MPI_Recv(&temp, 1, INT, MPI_ANY_SOURCE, 2, COMM_WORLD, &status);
            sum+=temp;
        }
        MPI_Send(&sum, 1, INT, 0, 3, COMM_WORLD);
    }
    else
    {
        int sum = 0;
        int items_to_process = 100;
        int items[items_to_process];
        COMM_WORLD.Recv(items, items_to_process, INT, 0, 2);
        for(int i = 0; i < items_to_process; i++)
        {
            sum += items[i];
        }
        float avg = (float)sum / (float)items_to_process;
        MPI_Send(&avg, 1, FLOAT, 0, 1, COMM_WORLD);
        MPI_Send(&sum, 1, INT, 1, 2, COMM_WORLD);
    }
    MPI::Finalize();
    return 0;
}