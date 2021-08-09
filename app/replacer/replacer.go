package replacer

import (
	"bytes"
	"io"
	"strings"
)

type Replacer interface {
	Replace(text string) string
	ReplaceAndWrite(out io.Writer, text string)
}

type replacer struct {
	separators [256]uint8
	dict       map[string]string
}

func New(dict map[string]string) Replacer {
	return &replacer{
		separators: convertSeparator(" \t\n\r,.:;?!\"()"),
		dict:       dict,
	}
}

func (t *replacer) Replace(text string) string {
	buf := new(bytes.Buffer)
	t.ReplaceAndWrite(buf, text)
	return buf.String()
}

func (t *replacer) ReplaceAndWrite(out io.Writer, text string) {
	lastCut := 0
	wasSeparator := false

	for i, c := range text {
		if t.separators[c] == 1 {
			t.replaceAndWrite(out, text[lastCut:i])
			lastCut = i
			wasSeparator = true
		} else {
			if wasSeparator {
				out.Write([]byte(text[lastCut:i]))
				lastCut = i
			}
			wasSeparator = false
		}
	}

	t.replaceAndWrite(out, text[lastCut:])
}

func (t *replacer) replaceAndWrite(out io.Writer, word string) {
	if replacement, ok := t.dict[strings.ToLower(word)]; ok {
		out.Write([]byte(replacement))
	} else {
		out.Write([]byte(word))
	}
}

func convertSeparator(sep string) [256]uint8 {
	separators := [256]uint8{}

	for _, r := range sep {
		separators[r] = 1
	}

	return separators
}
