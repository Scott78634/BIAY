// Function to create a scripture block (defined at the top level)
#let scripture(body) = {
  set text(font: "Gentium Book Basic", lang: "en", size: 16pt)
  align(left, body)
}

// Function to create a commentary block (defined at the top level)
#let commentary(body) = {
  set text(size: 10pt)
  align(left, body)
}


// Function to create a scriptref block (defined at the top level)
//#let scriptref(body) = block(
//    fill: luma(230),
//    inset: 12pt,
//    radius: 6pt,
//    body
//    )

// Function to create a scriptref block (defined at the top level)
#let scriptref(body) = {
    set text(font: "Gentium Book Basic", lang: "en", size: 16pt)
//    align(left, body)
    block(
    fill: luma(230),
    inset: 10pt,
    radius: 6pt,
    body
    )
    }



// Custom function for a single inline blank using 'line()' within a box
#let inline-blank(length: 20em, line-thickness: 0.5pt, line-color: black) = {
  h(0.5em) // Small space after text
  box(
    // The line should be positioned relative to the baseline of this box.
    // By setting the baseline to the bottom, the line will appear on the text baseline.
    baseline: 0em,
    // The content of the box is our line.
    line(length: length, stroke: line-thickness + line-color),
  )
}

// The project function defines how your document looks.
// It takes your content and some metadata and formats it.
// Go ahead and customize it to your liking!
#let project(title: "", authors: (), body) = {
  // Set the document's basic properties.
  set document(author: authors.map(a => a.name), title: title)
  set page(
    paper: "us-letter",
    flipped: true,
//    orientation: "landscape", // Changed to portrait for a more typical study layout, adjust if you truly want landscape
    columns: 1, // Two columns, equal width
//    column_gap: 1em, // Adjust as needed
    numbering: "1",
    number-align: center)
//  set text(font: "Libertinus Serif", lang: "en", size: 10pt)
  set text(font: "Latin Modern Sans", lang: "en", size: 16pt)


  // Title row.
  align(center)[
    #block(text(weight: 700, 1.75em, title))
  ]

  // Author information.
  pad(
    top: 0.5em,
    bottom: 0.5em,
    x: 2em,
    grid(
      columns: (1fr,) * calc.min(3, authors.len()),
      gutter: 1em,
      ..authors.map(author => align(center)[
        *#author.name* \
        #author.email \
        #author.affiliation \
        #author.date
      ]),
    ),
  )

  // Main body.
  set text(hyphenate: true)
//  show: columns.with(2, gutter: 1.3em) // This will apply to the body content

  body // This is where your main.typ content will be inserted
}
