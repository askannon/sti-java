
public class MainClass {

	public static void main(String[] args) throws InterruptedException {

		while(true) {
			Thread.sleep(10000L);
			System.out.println("Current timestamp: " + System.currentTimeMillis());
		}
		
	}

}
