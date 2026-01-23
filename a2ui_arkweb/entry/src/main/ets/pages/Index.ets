// Index.ets
import {A2UIInArkWeb} from './A2UIInArkweb'

@Entry
@Component
struct Index {
  build() {
    Column() {
      A2UIInArkWeb()
        .width('100%')
        .height('100%')
    }
  }
}