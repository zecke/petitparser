String extend [
    beginsWith: aString [
	<category: '*petitparser-core-converting-gst'>
	| res |

	res := self indexOf: aString matchCase: false startingAt: 1.
	res ifNil: [^false].

	^ res first = 1
    ]

    includesSubString: subString [
	<category: '*petitparser-core-converting-gst'>
	| res |

	res := self indexOf: subString matchCase: false startingAt: 1.
	res ifNil: [^false].

	^ res first >= 1
    ]
]

Symbol extend [
    value: anObject [
	<category: '*petitparser-core-converting-gst'>
	^anObject perform: self
    ]
]

Character extend [
    sameAs: aChar [
	<category: '*petitparser-core-converting-gst'>
	^self asLowercase = aChar asLowercase.
    ]
]

