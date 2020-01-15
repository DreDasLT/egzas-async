/*
1. Programos pradiniai duomenys - masyvas su visais sveikaisiais skaičiais nuo 0 iki 999 iš eilės imtinai. Išdalinti elementus po lygiai 10 procesų (nuo 0 iki 99 elemento, nuo 100 iki 199 ir t.t.).
    Kiekvienas gija randa savo dalies vidurkį (float tipo) ir persiunčia pagrindiniam procesui. Gauti vidurkiai išvedami ekrane. Realizuoti naudojantis GO kanalais arba MPI.

2. Modifikuokite programą, kad kiekvienas procesas surastų savo duomenų dalies sumą, ją persiųstų papildomam sumavimo procesui, kuris suranda jam siunčiamų dalinių sumų sumą ir persiunčia pagrindiniam procesui.
    Gaitas rezultatas išvedamas ekrane.
*/
package main

import "fmt"

func main() {
	rezultatai := make(chan int)
	rezultatai2 := make(chan int)
	for i := 0; i < 1000; i += 100 {
		go suma(i, i+99, rezultatai)
	}
	go Suma2x(rezultatai, rezultatai2)

	atsakymas := <-rezultatai2 // antras punktas
	fmt.Println(atsakymas)
}

func suma(pradzia int, pabaiga int, rezultatai chan int) {
	var skaiciavimas = 0
	for i := pradzia; i <= pabaiga; i++ {
		skaiciavimas += i
	}
	rezultatai <- skaiciavimas
}

func Suma2x(rezultatai chan int, rezultatai2 chan int) {
	var suma = 0
	go func() {
		close(rezultatai)
	}()
	for elementas := range rezultatai {
		fmt.Println(elementas)
		suma += elementas
	}
	rezultatai2 <- suma
}
