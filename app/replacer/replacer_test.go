package replacer

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func initReplacer() Replacer {
	return New(map[string]string{
		"abn":       "ABN AMRO",
		"ing":       "ING Bank",
		"rabo":      "Rabobank",
		"triodos":   "Triodos Bank",
		"volksbank": "de Volksbank",
	})
}
func TestRreplacer(t *testing.T) {
	replacer := initReplacer()

	result := replacer.Replace("The analysts of ABN did a great job!")

	assert.Equal(t, "The analysts of ABN AMRO did a great job!", result)
}

func TestRreplacerEmptyString(t *testing.T) {
	replacer := initReplacer()

	result := replacer.Replace("")

	assert.Equal(t, "", result)
}

func TestRreplacerSingle(t *testing.T) {
	replacer := initReplacer()

	result := replacer.Replace("triodos")

	assert.Equal(t, "Triodos Bank", result)
}

func TestRreplacerMultiple(t *testing.T) {
	replacer := initReplacer()

	result := replacer.Replace("The analysts of ABN did a great job! rAbO, iNG (and VolksBank) did well too.")

	assert.Equal(t, "The analysts of ABN AMRO did a great job! Rabobank, ING Bank (and de Volksbank) did well too.", result)
}

func BenchmarkTokenizer(b *testing.B) {
	replacer := initReplacer()

	for n := 0; n < b.N; n++ {
		replacer.Replace("The analysts of ABN did a great job!")
	}
}
