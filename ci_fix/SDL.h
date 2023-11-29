#ifndef _FAKE_SDL_H_
#define _FAKE_SDL_H_

// This is a "fix" for building on Windows.
// The Hashlink project follows different path format when building on
// Linux (include SDL2/SDL.h) and Windows (include SDL.h). We use this
// file to make building process moving forward.

#include <SDL2/SDL.h>

#endif /* _FAKE_SDL_H_ */
