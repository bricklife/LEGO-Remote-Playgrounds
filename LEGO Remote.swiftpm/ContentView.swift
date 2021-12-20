import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        VStack(spacing: 32) {
            HStack() {
                if viewModel.isScanning {
                    Button("Scanning...") {
                        viewModel.cancel()
                    }
                } else {
                    if let name = viewModel.peripheral?.name {
                        Button(action: { viewModel.disconnect() }) {
                            Image(systemName: "xmark.circle.fill")
                        }
                        Text(name)
                    } else {
                        Button("Connect") {
                            viewModel.connect()
                        }
                    }
                }
            }
            
            Group {
                Text("\(viewModel.power)")
                
                HStack {
                    Button(action: { viewModel.decrement() }) {
                        Image(systemName: "minus.circle")
                    }
                    Button(action: { viewModel.stop() }) {
                        Image(systemName: "stop.circle")
                    }
                    Button(action: { viewModel.increment() }) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .font(.system(size: 64))
        }
    }
}
